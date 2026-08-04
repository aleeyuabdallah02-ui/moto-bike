import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../services/referral_service.dart';
import '../theme/app_theme.dart';
import 'client_home_screen.dart';
import 'driver_home_screen.dart';

/// Single signup screen for the whole app — person picks Client or
/// Driver, then the same phone-only (no SMS OTP) flow applies to both.
/// This is the ONE app, role-based, as originally planned.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _referralController = TextEditingController();
  final _referralService = ReferralService();

  String _role = 'client'; // 'client' or 'driver'
  bool _submitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final referralCode = _referralController.text.trim().toUpperCase();

      if (referralCode.isNotEmpty) {
        final valid = await _referralService.isValidCode(referralCode);
        if (!valid) {
          setState(() {
            _errorMessage = AppLocalizations.t('invalid_referral');
            _submitting = false;
          });
          return;
        }
      }

      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user!.uid;
      final db = FirebaseDatabase.instance.ref();

      // Lightweight lookup node: lets main.dart quickly find a
      // returning user's role without scanning both drivers/ and clients/.
      await db.child('users/$uid').set({'role': _role});

      final path = _role == 'driver' ? 'drivers' : 'clients';

      await db.child('$path/$uid').set({
        'phoneNumber': phone,
        'name': _nameController.text.trim(),
        'referralCode': referralCode.isEmpty ? null : referralCode,
        'subscriptionActive': false, // both drivers AND clients pay subscription
        if (_role == 'driver') ...{
          'isOnline': false,
          'completedTrips': 0,
          'reportCount': 0,
          'trustLevel': 'newDriver',
          'hasUploadedId': false,
        },
        'createdAt': ServerValue.timestamp,
      });

      if (referralCode.isNotEmpty) {
        await _referralService.recordUsage(referralCode);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _role == 'driver' ? const DriverHomeScreen() : const ClientHomeScreen(),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Kuskure: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('signup_title')),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Role selector — the ONE decision that branches the rest
            // of the signup flow and which home screen you land on.
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    label: AppLocalizations.t('client'),
                    icon: Icons.person_outline,
                    selected: _role == 'client',
                    onTap: () => setState(() => _role = 'client'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleCard(
                    label: AppLocalizations.t('driver'),
                    icon: Icons.two_wheeler_outlined,
                    selected: _role == 'driver',
                    onTap: () => setState(() => _role = 'driver'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: AppLocalizations.t('name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppLocalizations.t('phone_number'),
                hintText: '+237 6XX XXX XXX',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referralController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: AppLocalizations.t('referral_code'),
                hintText: 'MOTO014',
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: AppLocalizations.t('continue'),
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFF262B3D),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
