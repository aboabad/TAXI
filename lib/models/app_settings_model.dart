class AppSettingsModel {
  double restaurantCommissionRate; // e.g., 0.10 for 10%
  double driverCommissionPerDinar; // e.g., 0.15 JOD
  double deliveryRatePerKm; // e.g., 0.50 JOD
  double minDeliveryDistance; // e.g., 2.0 km

  AppSettingsModel({
    this.restaurantCommissionRate = 0.10,
    this.driverCommissionPerDinar = 0.15,
    this.deliveryRatePerKm = 0.50,
    this.minDeliveryDistance = 2.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantCommissionRate': restaurantCommissionRate,
      'driverCommissionPerDinar': driverCommissionPerDinar,
      'deliveryRatePerKm': deliveryRatePerKm,
      'minDeliveryDistance': minDeliveryDistance,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      restaurantCommissionRate: (map['restaurantCommissionRate'] ?? 0.10).toDouble(),
      driverCommissionPerDinar: (map['driverCommissionPerDinar'] ?? 0.15).toDouble(),
      deliveryRatePerKm: (map['deliveryRatePerKm'] ?? 0.50).toDouble(),
      minDeliveryDistance: (map['minDeliveryDistance'] ?? 2.0).toDouble(),
    );
  }
}
