import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../theme/app_theme.dart';
import 'subscription_payment_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _driverService = DriverService();
  bool _isOnline = false;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _toggleOnline(bool value) async {
    if (value) {
      final success = await _driverService.goOnline(_uid);
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription ɗinka ya ƙare. Ka biya don ci gaba da karɓar orders.'),
          ),
        );
        return;
      }
    } else {
      await _driverService.goOffline(_uid);
    }
    setState(() => _isOnline = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: 'Subscription',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubscriptionPaymentScreen(
                    userId: _uid,
                    role: 'driver',
                    phoneNumber: '', // TODO: pull the driver's stored phone number
                  ),
                ),
              );
            },
          ),
          Switch(
            value: _isOnline,
            onChanged: _toggleOnline,
            activeColor: AppTheme.primary,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isOnline
          ? StreamBuilder<Map<String, dynamic>?>(
              stream: _driverService.incomingRequest(_uid),
              builder: (context, snapshot) {
                final request = snapshot.data;
                if (request == null) {
                  return const Center(
                    child: Text('Ana jiran order...', style: TextStyle(color: AppTheme.textSecondary)),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sabon Order 🚕',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Zuwa: ${request['destinationAddress'] ?? ''}'),
                          const SizedBox(height: 20),
                          GradientButton(
                            label: 'Karɓa',
                            onPressed: () => _driverService.acceptOrder(request['orderId'], _uid),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Text('Ka kunna "Online" don karɓar orders',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
    );
  }
}
