import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/monetbil_service.dart';
import '../theme/app_theme.dart';

/// Lets a driver or client pick a subscription plan (1/6/12 months)
/// and pay it via MTN MoMo / Orange Money. Runs entirely from the
/// phone — no server involved.
class SubscriptionPaymentScreen extends StatefulWidget {
  final String userId;
  final String role; // 'driver' or 'client'
  final String phoneNumber;

  const SubscriptionPaymentScreen({
    super.key,
    required this.userId,
    required this.role,
    required this.phoneNumber,
  });

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  final _monetbil = MonetbilService();
  String _status = 'idle'; // idle | waiting | success | failed
  SubscriptionPlan _selectedPlan = SubscriptionPlan.oneMonth;

  Future<void> _startPayment() async {
    setState(() => _status = 'waiting');

    try {
      final link = await _monetbil.createPaymentLink(
        userId: widget.userId,
        role: widget.role,
        phoneNumber: widget.phoneNumber,
        plan: _selectedPlan,
      );

      await launchUrl(Uri.parse(link['paymentUrl']!), mode: LaunchMode.externalApplication);

      final paid = await _monetbil.pollUntilPaid(link['paymentRef']!);

      if (paid) {
        await _monetbil.activateSubscription(
          userId: widget.userId,
          role: widget.role,
          plan: _selectedPlan,
        );
        setState(() => _status = 'success');
      } else {
        setState(() => _status = 'failed');
      }
    } catch (e) {
      setState(() => _status = 'failed');
    }
  }

  Widget _planCard(SubscriptionPlan plan) {
    final selected = _selectedPlan == plan;
    return GestureDetector(
      onTap: _status == 'idle' ? () => setState(() => _selectedPlan = plan) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFF262B3D),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(plan.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biyan Subscription')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_status == 'idle') ...[
              _planCard(SubscriptionPlan.oneMonth),
              _planCard(SubscriptionPlan.sixMonths),
              _planCard(SubscriptionPlan.oneYear),
              const SizedBox(height: 12),
              GradientButton(
                label: 'Biya ta MTN MoMo / Orange Money',
                onPressed: _startPayment,
              ),
            ],
            if (_status == 'waiting') ...[
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Ka duba wayarka — za ka samu USSD prompt don shigar da PIN ɗinka don kammala biya.',
                textAlign: TextAlign.center,
              ),
            ],
            if (_status == 'success')
              Text('✅ An biya! Subscription ɗinka yana aiki (${_selectedPlan.label}).',
                  style: const TextStyle(color: AppTheme.success, fontSize: 16)),
            if (_status == 'failed') ...[
              const Text('❌ Biya bai yi nasara ba.', style: TextStyle(color: AppTheme.danger)),
              const SizedBox(height: 12),
              GradientButton(label: 'Sake Gwadawa', onPressed: () {
                setState(() => _status = 'idle');
              }),
            ],
          ],
        ),
      ),
    );
  }
}
