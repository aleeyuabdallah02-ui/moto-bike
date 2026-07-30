import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

/// The three subscription tiers, chosen to reward longer commitments.
enum SubscriptionPlan { oneMonth, sixMonths, oneYear }

extension SubscriptionPlanDetails on SubscriptionPlan {
  int get amountFcfa {
    switch (this) {
      case SubscriptionPlan.oneMonth:
        return 100;
      case SubscriptionPlan.sixMonths:
        return 500;
      case SubscriptionPlan.oneYear:
        return 1000;
    }
  }

  int get durationDays {
    switch (this) {
      case SubscriptionPlan.oneMonth:
        return 30;
      case SubscriptionPlan.sixMonths:
        return 182; // ~6 months
      case SubscriptionPlan.oneYear:
        return 365;
    }
  }

  String get label {
    switch (this) {
      case SubscriptionPlan.oneMonth:
        return '100 FCFA — Wata Guda';
      case SubscriptionPlan.sixMonths:
        return '500 FCFA — Wata 6';
      case SubscriptionPlan.oneYear:
        return '1000 FCFA — Shekara Guda';
    }
  }
}

/// Handles subscription payment entirely from the app —
/// NO Cloud Functions, NO Blaze plan, NO bank card required on our side.
///
/// Flow:
/// 1. App calls Monetbil's Widget API directly to get a payment link
/// 2. App opens that link (url_launcher) — user pays via MoMo/Orange
///    USSD prompt on THEIR OWN phone
/// 3. App polls Monetbil's checkPayment API every few seconds
/// 4. Once payment succeeds, the app itself writes subscriptionActive
///    to Realtime Database (a normal client-side write, free)
///
/// NOTE ON SECURITY: the Monetbil service key is embedded in the app
/// here because we have no server to hold it safely. Accepted trade-off
/// at this small scale. Move to backend/functions later if it grows.
class MonetbilService {
  static const String _serviceKey = 'PASTE_YOUR_MONETBIL_SERVICE_KEY_HERE';

  static const String _widgetUrl = 'https://api.monetbil.com/widget/v2.1/';
  static const String _checkPaymentUrl = 'https://api.monetbil.com/payment/v1/checkPayment';

  Future<Map<String, String>> createPaymentLink({
    required String userId,
    required String role, // 'driver' or 'client'
    required String phoneNumber,
    required SubscriptionPlan plan,
  }) async {
    final itemRef = '${role}_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    final response = await http.post(
      Uri.parse('$_widgetUrl$_serviceKey'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'amount': plan.amountFcfa.toString(),
        'phone': phoneNumber,
        'phone_lock': 'false',
        'locale': 'fr',
        'country': 'CM',
        'currency': 'XAF',
        'item_ref': itemRef,
        'payment_ref': itemRef,
        'user': userId,
      },
    );

    final result = jsonDecode(response.body);
    if (result['success'] != true) {
      throw Exception('Monetbil ya ki payment request: ${result['message']}');
    }

    return {
      'paymentUrl': result['payment_url'],
      'paymentRef': itemRef,
    };
  }

  Future<bool> pollUntilPaid(String paymentRef, {int maxAttempts = 40}) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(const Duration(seconds: 5));

      final response = await http.post(
        Uri.parse(_checkPaymentUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'service': _serviceKey,
          'payment_ref': paymentRef,
        },
      );

      final result = jsonDecode(response.body);
      if (result['status'] == 1) return true;
      if (result['status'] == 0 || result['status'] == -1) return false;
    }
    return false;
  }

  /// Once payment is confirmed, activate the subscription for the
  /// chosen plan's duration — directly from the app.
  Future<void> activateSubscription({
    required String userId,
    required String role,
    required SubscriptionPlan plan,
  }) async {
    final path = role == 'driver' ? 'drivers' : 'clients';
    final expiry = DateTime.now().add(Duration(days: plan.durationDays));
    final db = FirebaseDatabase.instance.ref();

    await db.child('$path/$userId').update({
      'subscriptionActive': true,
      'subscriptionExpiry': expiry.millisecondsSinceEpoch,
      'subscriptionPlan': plan.name,
    });

    await db.child('subscriptions').push().set({
      'userId': userId,
      'role': role,
      'plan': plan.name,
      'amount': plan.amountFcfa,
      'paidAt': ServerValue.timestamp,
      'expiresAt': expiry.millisecondsSinceEpoch,
    });
  }
}
