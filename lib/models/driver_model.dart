/// A driver's trust level is earned through behavior on the platform,
/// not through ID/license verification (many drivers don't have one).
enum TrustLevel { newDriver, trusted, suspended }

class DriverModel {
  final String uid;
  final String phoneNumber;
  final String? name;
  bool isOnline;
  bool subscriptionActive;
  int? subscriptionExpiry; // millisecondsSinceEpoch
  double? lat;
  double? lng;

  // --- Trust system fields (behavior-based, not ID-based) ---
  int completedTrips;
  int reportCount;
  TrustLevel trustLevel;
  String? referredByCode; // referral code used at signup, e.g. "MOTO014"
  bool hasUploadedId;

  DriverModel({
    required this.uid,
    required this.phoneNumber,
    this.name,
    this.isOnline = false,
    this.subscriptionActive = false,
    this.subscriptionExpiry,
    this.lat,
    this.lng,
    this.completedTrips = 0,
    this.reportCount = 0,
    this.trustLevel = TrustLevel.newDriver,
    this.referredByCode,
    this.hasUploadedId = false,
  });

  static const int tripsRequiredForTrustedBadge = 10;
  static const int reportsBeforeAutoSuspend = 3;

  Map<String, dynamic> toMap() => {
        'phoneNumber': phoneNumber,
        'name': name,
        'isOnline': isOnline,
        'subscriptionActive': subscriptionActive,
        'subscriptionExpiry': subscriptionExpiry,
        'lat': lat,
        'lng': lng,
        'completedTrips': completedTrips,
        'reportCount': reportCount,
        'trustLevel': trustLevel.name,
        'referredByCode': referredByCode,
        'hasUploadedId': hasUploadedId,
      };

  factory DriverModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return DriverModel(
      uid: uid,
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'],
      isOnline: map['isOnline'] ?? false,
      subscriptionActive: map['subscriptionActive'] ?? false,
      subscriptionExpiry: map['subscriptionExpiry'],
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      completedTrips: map['completedTrips'] ?? 0,
      reportCount: map['reportCount'] ?? 0,
      trustLevel: TrustLevel.values.firstWhere(
        (e) => e.name == map['trustLevel'],
        orElse: () => TrustLevel.newDriver,
      ),
      referredByCode: map['referredByCode'],
      hasUploadedId: map['hasUploadedId'] ?? false,
    );
  }
}
