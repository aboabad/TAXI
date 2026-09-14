import 'package:flutter_test/flutter_test.dart';
import 'package:taxi/core/billing_calculator.dart';
import 'package:taxi/models/app_settings_model.dart';

void main() {
  group('BillingCalculator', () {
    final calculator = BillingCalculator(
      AppSettingsModel(
        restaurantCommissionRate: 0.10,
        driverCommissionPerDinar: 0.15,
        deliveryRatePerKm: 0.50,
        minDeliveryDistance: 2,
      ),
    );

    test('calculates chargeable distance safely', () {
      expect(
        calculator.calculateChargeableDistance(
          outboundDistanceKm: 3,
          returnDistanceKm: 2,
        ),
        5,
      );
      expect(
        calculator.calculateChargeableDistance(
          outboundDistanceKm: -1,
          returnDistanceKm: 2,
        ),
        2,
      );
    });

    test('calculates a complete bill', () {
      final result = calculator.calculate(
        restaurantOrderValue: 20,
        outboundDistanceKm: 2,
        returnDistanceKm: 2,
      );

      expect(result.deliveryFee, 2);
      expect(result.restaurantCommission, 2);
      expect(result.restaurantNetAmount, 18);
      expect(result.driverCommission, 0.30);
      expect(result.driverNetAmount, 1.70);
      expect(result.adminRevenue, 2.30);
      expect(result.totalCustomerBill, 22);
    });
  });
}
