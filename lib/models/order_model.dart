enum OrderStatus { pending, accepted, ongoing, completed, cancelled, noDriversFound }

class OrderModel {
  final String id;
  final String clientId;
  String? driverId;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final String pickupAddress;
  final String destinationAddress;
  OrderStatus status;
  final int createdAt; // millisecondsSinceEpoch

  OrderModel({
    required this.id,
    required this.clientId,
    this.driverId,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.pickupAddress,
    required this.destinationAddress,
    this.status = OrderStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'driverId': driverId,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'status': status.name,
        'createdAt': createdAt,
      };

  factory OrderModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return OrderModel(
      id: id,
      clientId: map['clientId'] ?? '',
      driverId: map['driverId'],
      pickupLat: (map['pickupLat'] ?? 0).toDouble(),
      pickupLng: (map['pickupLng'] ?? 0).toDouble(),
      destinationLat: (map['destinationLat'] ?? 0).toDouble(),
      destinationLng: (map['destinationLng'] ?? 0).toDouble(),
      pickupAddress: map['pickupAddress'] ?? '',
      destinationAddress: map['destinationAddress'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: map['createdAt'] ?? 0,
    );
  }
}
