import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../localization/app_localizations.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import 'order_tracking_screen.dart';
import 'subscription_payment_screen.dart';

/// Client picks a destination on the map and requests a moto-taxi.
class PlaceOrderScreen extends StatefulWidget {
  final LatLng currentPosition;
  const PlaceOrderScreen({super.key, required this.currentPosition});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _orderService = OrderService();
  LatLng? _destination;
  bool _submitting = false;

  void _onMapTap(LatLng point) {
    setState(() => _destination = point);
  }

  Future<void> _openSubscription() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseDatabase.instance.ref('clients/$uid/phoneNumber').get();
    final phone = snapshot.value as String? ?? '';

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionPaymentScreen(userId: uid, role: 'client', phoneNumber: phone),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    if (_destination == null) return;
    setState(() => _submitting = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final orderId = await _orderService.placeOrder(
      clientId: uid,
      pickupLat: widget.currentPosition.latitude,
      pickupLng: widget.currentPosition.longitude,
      destinationLat: _destination!.latitude,
      destinationLng: _destination!.longitude,
      pickupAddress: 'Wurin Yanzu', // TODO: reverse-geocode to real address
      destinationAddress: 'Zaɓaɓɓen Wuri',
    );

    // Kick off client-side matching (no server needed — see order_service.dart).
    // Deliberately not awaited: it keeps running while the client watches
    // OrderTrackingScreen for status updates.
    _orderService.startMatching(
      orderId,
      widget.currentPosition.latitude,
      widget.currentPosition.longitude,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('choose_destination')),
        actions: [
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: 'Subscription',
            onPressed: _openSubscription,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.currentPosition, zoom: 15),
            onTap: _onMapTap,
            myLocationEnabled: true,
            markers: {
              Marker(markerId: const MarkerId('pickup'), position: widget.currentPosition),
              if (_destination != null)
                Marker(markerId: const MarkerId('destination'), position: _destination!),
            },
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: GradientButton(
              label: AppLocalizations.t('find_driver'),
              loading: _submitting,
              onPressed: _destination == null || _submitting ? null : _confirmOrder,
            ),
          ),
        ],
      ),
    );
  }
}
