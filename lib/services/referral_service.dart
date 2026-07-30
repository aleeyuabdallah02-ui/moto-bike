import 'package:firebase_database/firebase_database.dart';

/// Handles referral codes (e.g. "MOTO014") that content creators hand
/// out. Tracks how many people signed up using each code, so the
/// founder can see which creator is driving the most signups.
class ReferralService {
  final _db = FirebaseDatabase.instance.ref();

  /// Call this once, the first time the app runs against a fresh
  /// database, to seed all 50 codes (MOTO001..MOTO050). Safe to call
  /// multiple times — uses `update` so it won't overwrite existing
  /// usage counts.
  Future<void> seedReferralCodes() async {
    final codes = <String, dynamic>{};
    for (int i = 1; i <= 50; i++) {
      final code = 'MOTO${i.toString().padLeft(3, '0')}';
      codes[code] = {
        'assignedTo': '', // fill in later from Firebase Console once you give the code to a creator
        'usageCount': 0,
      };
    }
    // Using `update` on each key individually (not a blanket set) so
    // re-running this never resets a code's usageCount back to 0.
    for (final entry in codes.entries) {
      final existing = await _db.child('referralCodes/${entry.key}').get();
      if (!existing.exists) {
        await _db.child('referralCodes/${entry.key}').set(entry.value);
      }
    }
  }

  /// Returns true if the code exists (so the UI can show a friendly
  /// "✓ Valid code" or "Code not found" message).
  Future<bool> isValidCode(String code) async {
    if (code.isEmpty) return true; // referral code is optional
    final snapshot = await _db.child('referralCodes/$code').get();
    return snapshot.exists;
  }

  /// Call after a signup completes successfully, if a code was entered.
  Future<void> recordUsage(String code) async {
    if (code.isEmpty) return;
    final ref = _db.child('referralCodes/$code/usageCount');
    await ref.runTransaction((Object? current) {
      final count = (current as int?) ?? 0;
      return Transaction.success(count + 1);
    });
  }
}
