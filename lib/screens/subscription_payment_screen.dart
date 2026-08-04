import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';

/// Manual subscription flow (no Monetbil — that requires business
/// registration we're deferring, see README decisions log).
///
/// Flow: person sends money to the founder's own MoMo/Orange Money
/// number, then submits the transaction reference here. This gets
/// queued in `pendingConfirmations/` for the founder to review in a
/// daily batch and approve from the Firebase Console — NOT one-by-one
/// in real time.
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

enum _Plan { oneMonth, sixMonths, oneYear }

extension on _Plan {
  int get amount => switch (this) { _Plan.oneMonth => 100, _Plan.sixMonths => 500, _Plan.oneYear => 1000 };
  String label(BuildContext context) => switch (this) {
        _Plan.oneMonth => '100 FCFA',
        _Plan.sixMonths => '500 FCFA',
        _Plan.oneYear => '1000 FCFA',
      };
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  _Plan _selectedPlan = _Plan.oneMonth;
  final _referenceController = TextEditingController();
  bool _submitted = false;
  bool _submitting = false;

  // TODO: replace with the founder's real MTN MoMo / Orange Money numbers.
  static const String momoNumber = '+237679849700';
  static const String orangeNumber = '+237691967650';

  Future<void> _submitReference() async {
    final ref = _referenceController.text.trim();
    if (ref.isEmpty) return;

    setState(() => _submitting = true);

    await FirebaseDatabase.instance.ref('pendingConfirmations').push().set({
      'userId': widget.userId,
      'role': widget.role,
      'phoneNumber': widget.phoneNumber,
      'plan': _selectedPlan.name,
      'amount': _selectedPlan.amount,
      'transactionReference': ref,
      'submittedAt': ServerValue.timestamp,
      'status': 'pending',
    });

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.t('pay_subscription'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _submitted ? _buildSubmittedState() : _buildFormState(),
      ),
    );
  }

  Widget _buildSubmittedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 48),
        const SizedBox(height: 16),
        Text(AppLocalizations.t('submission_received'), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppLocalizations.t('choose_plan'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._Plan.values.map((plan) => _planCard(plan)),
          const SizedBox(height: 24),
          Text(AppLocalizations.t('send_payment_to'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _paymentNumberCard('MTN MoMo', momoNumber),
          const SizedBox(height: 8),
          _paymentNumberCard('Orange Money', orangeNumber),
          const SizedBox(height: 24),
          Text(AppLocalizations.t('enter_reference'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(AppLocalizations.t('reference_hint'), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(labelText: 'Transaction Reference'),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: AppLocalizations.t('submit'),
            loading: _submitting,
            onPressed: _referenceController.text.trim().isEmpty || _submitting ? null : _submitReference,
          ),
        ],
      ),
    );
  }

  Widget _planCard(_Plan plan) {
    final selected = _selectedPlan == plan;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : const Color(0xFF262B3D), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 12),
            Text(plan.label(context)),
          ],
        ),
      ),
    );
  }

  Widget _paymentNumberCard(String provider, String number) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(provider, style: const TextStyle(fontWeight: FontWeight.w600)),
          SelectableText(number, style: const TextStyle(color: AppTheme.primary)),
        ],
      ),
    );
  }
}
