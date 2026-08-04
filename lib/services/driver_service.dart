import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

/// Handles a driver's online/offline state, live location, order
/// acceptance, and trust system — all via Firebase Realtime Database
/// (free, no billing account needed), no Cloud Functions required.
class DriverService {
  final _db = FirebaseDatabase.instance.ref();

  Future<bool> goOnline(String driverId) async {
    final snapshot = await _db.child('drivers/$driverId/subscriptionActive').get();
    if (snapshot.value != true) return false;

    final position = await Geolocator.getCurrentPosition();

    await _db.child('drivers/$driverId').update({
      'isOnline': true,
      'lat': position.latitude,
      'lng': position.longitude,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });

    return true;
  }

  Future<void> goOffline(String driverId) async {
    await _db.child('drivers/$driverId/isOnline').set(false);
  }

  Future<void> updateLocation(String driverId, double lat, double lng) async {
    await _db.child('drivers/$driverId').update({
      'lat': lat,
      'lng': lng,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Stream of incoming order requests assigned to this driver.
  Stream<Map<String, dynamic>?> incomingRequest(String driverId) {
    return FirebaseDatabase.instance
        .ref('orders')
        .orderByChild('candidateDriverId')
        .equalTo(driverId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return null;
      final ordersMap = event.snapshot.value as Map<dynamic, dynamic>;
      for (final entry in ordersMap.entries) {
        final order = entry.value as Map<dynamic, dynamic>;
        if (order['status'] == 'pending') {
          return {'orderId': entry.key, ...Map<String, dynamic>.from(order)};
        }
      }
      return null;
    });
  }

  /// Runs a Realtime Database transaction so two drivers can't both
  /// accept the same order — safe even without a server.
  Future<bool> acceptOrder(String orderId, String driverId) async {
    final ref = _db.child('orders/$orderId');
    final result = await ref.runTransaction((Object? currentData) {
      if (currentData == null) return Transaction.abort();
      final data = Map<String, dynamic>.from(currentData as Map);
      if (data['status'] != 'pending') return Transaction.abort();
      data['status'] = 'accepted';
      data['driverId'] = driverId;
      return Transaction.success(data);
    });
    return result.committed;
  }

  Future<void> markTripCompletedAndUpdateTrust(String orderId, String driverId) async {
    await _db.child('orders/$orderId/status').set('completed');

    final ref = _db.child('drivers/$driverId');
    await ref.runTransaction((Object? currentData) {
      if (currentData == null) return Transaction.abort();
      final data = Map<String, dynamic>.from(currentData as Map);
      final newTripCount = (data['completedTrips'] ?? 0) + 1;
      data['completedTrips'] = newTripCount;

      if (newTripCount >= 10 &&
          (data['reportCount'] ?? 0) == 0 &&
          data['trustLevel'] == 'newDriver') {
        data['trustLevel'] = 'trusted';
      }
      return Transaction.success(data);
    });
  }

  Future<void> reportDriver(String driverId, String orderId, String reason) async {
    await _db.child('reports').push().set({
      'driverId': driverId,
      'orderId': orderId,
      'reason': reason,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    final ref = _db.child('drivers/$driverId');
    await ref.runTransaction((Object? currentData) {
      if (currentData == null) return Transaction.abort();
      final data = Map<String, dynamic>.from(currentData as Map);
      final newReportCount = (data['reportCount'] ?? 0) + 1;
      data['reportCount'] = newReportCount;

      if (newReportCount >= 3) {
        data['trustLevel'] = 'suspended';
        data['isOnline'] = false;
      }
      return Transaction.success(data);
    });
  }
}
