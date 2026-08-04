import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order_model.dart';

/// Handles creating orders and finding nearby available drivers.
/// Rewritten for Firebase Realtime Database (no billing account
/// required, unlike Firestore). Matching runs CLIENT-SIDE on the
/// client's own phone — no server / Cloud Functions needed.
class OrderService {
  final _db = FirebaseDatabase.instance.ref();

  Future<String> placeOrder({
    required String clientId,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String pickupAddress,
    required String destinationAddress,
  }) async {
    final ref = _db.child('orders').push();

    final order = OrderModel(
      id: ref.key!,
      clientId: clientId,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await ref.set(order.toMap());
    return ref.key!;
  }

  Stream<OrderModel> watchOrder(String orderId) {
    return _db.child('orders/$orderId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return OrderModel.fromMap(orderId, data);
    });
  }

  /// CLIENT-SIDE MATCHING: fetch all online+subscribed+trusted drivers,
  /// sort by distance, try each one in turn with a 20s timeout.
  Future<void> startMatching(String orderId, double pickupLat, double pickupLng) async {
    final snapshot = await _db.child('drivers').get();
    if (!snapshot.exists) {
      await _db.child('orders/$orderId/status').set('noDriversFound');
      return;
    }

    final driversMap = snapshot.value as Map<dynamic, dynamic>;
    final candidates = <MapEntry<String, double>>[];

    driversMap.forEach((key, value) {
      final d = value as Map<dynamic, dynamic>;
      final isOnline = d['isOnline'] == true;
      final subActive = d['subscriptionActive'] == true;
      final trustLevel = d['trustLevel'] ?? 'newDriver';
      final lat = (d['lat'] as num?)?.toDouble();
      final lng = (d['lng'] as num?)?.toDouble();

      if (isOnline && subActive && trustLevel != 'suspended' && lat != null && lng != null) {
        final distance = Geolocator.distanceBetween(pickupLat, pickupLng, lat, lng);
        if (distance <= 5000) {
          // within 5km
          candidates.add(MapEntry(key as String, distance));
        }
      }
    });

    if (candidates.isEmpty) {
      await _db.child('orders/$orderId/status').set('noDriversFound');
      return;
    }

    candidates.sort((a, b) => a.value.compareTo(b.value)); // nearest first

    for (final entry in candidates) {
      final driverId = entry.key;

      await _db.child('orders/$orderId').update({
        'candidateDriverId': driverId,
        'status': 'pending',
      });

      final accepted = await _waitForAcceptance(orderId, timeoutSeconds: 20);
      if (accepted) return;

      final current = await _db.child('orders/$orderId/status').get();
      if (current.value == 'cancelled') return;
    }

    await _db.child('orders/$orderId/status').set('noDriversFound');
  }

  Future<bool> _waitForAcceptance(String orderId, {required int timeoutSeconds}) async {
    try {
      final event = await _db
          .child('orders/$orderId/status')
          .onValue
          .firstWhere((e) => e.snapshot.value == 'accepted')
          .timeout(Duration(seconds: timeoutSeconds));
      return event.snapshot.value == 'accepted';
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await _db.child('orders/$orderId/status').set('cancelled');
  }
}
