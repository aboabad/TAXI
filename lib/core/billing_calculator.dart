import 'package:taxi/models/app_settings_model.dart';

class BillingCalculationResult {
  final double restaurantOrderValue;

  // المسافات التي يدفعها الزبون فقط
  final double outboundDistanceKm;
  final double returnDistanceKm;
  final double chargeableDistanceKm;

  // الزبون
  final double deliveryFee;
  final double totalCustomerBill;

  // المطعم
  final double restaurantCommissionRate;
  final double restaurantCommission;
  final double restaurantNetAmount;

  // السائق
  final double driverCommissionRate;
  final double driverCommission;
  final double driverNetAmount;

  // الإدارة
  final double adminRevenue;

  const BillingCalculationResult({
    required this.restaurantOrderValue,
    required this.outboundDistanceKm,
    required this.returnDistanceKm,
    required this.chargeableDistanceKm,
    required this.deliveryFee,
    required this.totalCustomerBill,
    required this.restaurantCommissionRate,
    required this.restaurantCommission,
    required this.restaurantNetAmount,
    required this.driverCommissionRate,
    required this.driverCommission,
    required this.driverNetAmount,
    required this.adminRevenue,
  });
}

class BillingCalculator {
  final AppSettingsModel settings;

  BillingCalculator(this.settings);

  // ============================================================
  // المسافة المحتسبة على الزبون
  // ============================================================

  /// المسافة التي يدفعها الزبون:
  ///
  /// موقع الانطلاق → المطعم
  /// +
  /// المطعم → موقع العودة
  ///
  /// لا يتم احتساب:
  /// السائق → موقع الانطلاق
  double calculateChargeableDistance({
    required double outboundDistanceKm,
    required double returnDistanceKm,
  }) {
    final safeOutbound =
    outboundDistanceKm < 0 ? 0.0 : outboundDistanceKm;

    final safeReturn =
    returnDistanceKm < 0 ? 0.0 : returnDistanceKm;

    return safeOutbound + safeReturn;
  }

  // ============================================================
  // أجرة التوصيل
  // ============================================================

  double calculateDeliveryFeeFromDistance(
      double distanceKm,
      ) {
    final safeDistance =
    distanceKm < 0 ? 0.0 : distanceKm;

    final effectiveDistance =
    safeDistance < settings.minDeliveryDistance
        ? settings.minDeliveryDistance
        : safeDistance;

    return effectiveDistance *
        settings.deliveryRatePerKm;
  }

  /// حساب أجرة الذهاب والعودة.
  double calculateDeliveryFee({
    required double outboundDistanceKm,
    required double returnDistanceKm,
  }) {
    final totalDistance =
    calculateChargeableDistance(
      outboundDistanceKm:
      outboundDistanceKm,
      returnDistanceKm:
      returnDistanceKm,
    );

    return calculateDeliveryFeeFromDistance(
      totalDistance,
    );
  }

  // ============================================================
  // عمولة المطعم
  // ============================================================

  double calculateRestaurantCommission(
      double orderValue, {
        double? restaurantCommissionRate,
      }) {
    final safeOrderValue =
    orderValue < 0 ? 0.0 : orderValue;

    final rate =
        restaurantCommissionRate ??
            settings.restaurantCommissionRate;

    return safeOrderValue * rate;
  }

  // ============================================================
  // عمولة السائق
  // ============================================================

  double calculateDriverCommission(
      double deliveryFee,
      ) {
    final safeDeliveryFee =
    deliveryFee < 0 ? 0.0 : deliveryFee;

    return safeDeliveryFee *
        settings.driverCommissionPerDinar;
  }

  // ============================================================
  // الحساب الكامل
  // ============================================================

  BillingCalculationResult calculate({
    required double restaurantOrderValue,
    required double outboundDistanceKm,
    required double returnDistanceKm,
    double? restaurantCommissionRate,
  }) {
    final chargeableDistanceKm =
    calculateChargeableDistance(
      outboundDistanceKm:
      outboundDistanceKm,
      returnDistanceKm:
      returnDistanceKm,
    );

    final deliveryFee =
    calculateDeliveryFeeFromDistance(
      chargeableDistanceKm,
    );

    final effectiveRestaurantRate =
        restaurantCommissionRate ??
            settings.restaurantCommissionRate;

    final restaurantCommission =
    calculateRestaurantCommission(
      restaurantOrderValue,
      restaurantCommissionRate:
      effectiveRestaurantRate,
    );

    final restaurantNetAmount =
        restaurantOrderValue -
            restaurantCommission;

    final driverCommission =
    calculateDriverCommission(
      deliveryFee,
    );

    final driverNetAmount =
        deliveryFee -
            driverCommission;

    final adminRevenue =
        restaurantCommission +
            driverCommission;

    final totalCustomerBill =
        restaurantOrderValue +
            deliveryFee;

    return BillingCalculationResult(
      restaurantOrderValue:
      restaurantOrderValue,

      outboundDistanceKm:
      outboundDistanceKm,

      returnDistanceKm:
      returnDistanceKm,

      chargeableDistanceKm:
      chargeableDistanceKm,

      deliveryFee:
      deliveryFee,

      totalCustomerBill:
      totalCustomerBill,

      restaurantCommissionRate:
      effectiveRestaurantRate,

      restaurantCommission:
      restaurantCommission,

      restaurantNetAmount:
      restaurantNetAmount,

      driverCommissionRate:
      settings.driverCommissionPerDinar,

      driverCommission:
      driverCommission,

      driverNetAmount:
      driverNetAmount,

      adminRevenue:
      adminRevenue,
    );
  }

  // ============================================================
  // فاتورة الزبون فقط
  // ============================================================

  double calculateTotalCustomerBill({
    required double orderValue,
    required double outboundDistanceKm,
    required double returnDistanceKm,
  }) {
    final deliveryFee =
    calculateDeliveryFee(
      outboundDistanceKm:
      outboundDistanceKm,
      returnDistanceKm:
      returnDistanceKm,
    );

    return orderValue + deliveryFee;
  }
}