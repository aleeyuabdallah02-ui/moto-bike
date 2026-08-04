import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';

/// Client watches this screen live while waiting for / riding with a driver.
class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  final _orderService = OrderService();

  OrderTrackingScreen({super.key, required this.orderId});

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppLocalizations.t('searching_driver');
      case OrderStatus.accepted:
        return AppLocalizations.t('driver_accepted');
      case OrderStatus.ongoing:
        return AppLocalizations.t('trip_ongoing');
      case OrderStatus.completed:
        return AppLocalizations.t('trip_completed');
      case OrderStatus.cancelled:
        return AppLocalizations.t('trip_cancelled');
      case OrderStatus.noDriversFound:
        return AppLocalizations.t('no_drivers_found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.t('trip_status'))),
      body: StreamBuilder<OrderModel>(
        stream: _orderService.watchOrder(orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _statusText(order.status),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (order.driverId != null)
                  Text('Driver ID: ${order.driverId}'), // TODO: show driver name/phone/photo
                const SizedBox(height: 32),
                if (order.status == OrderStatus.pending)
                  OutlinedButton(
                    onPressed: () => _orderService.cancelOrder(orderId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                    child: Text(AppLocalizations.t('cancel_trip')),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
