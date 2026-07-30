import 'package:flutter/material.dart';
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
        return 'Ana neman direba mafi kusa...';
      case OrderStatus.accepted:
        return 'Direba ya karɓa! Yana zuwa gareka.';
      case OrderStatus.ongoing:
        return 'Kana tafiya...';
      case OrderStatus.completed:
        return 'Tafiya ta ƙare. Na gode!';
      case OrderStatus.cancelled:
        return 'An soke wannan tafiya.';
      case OrderStatus.noDriversFound:
        return 'Babu direba a yankinka a yanzu. Za mu sanar da kai da zarar an samu.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matsayin Tafiya')),
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
                    child: const Text('Soke Tafiya'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
