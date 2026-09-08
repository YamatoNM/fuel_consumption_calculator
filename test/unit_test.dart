import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_consumption_calculator/models/vehicle.dart';
import 'package:fuel_consumption_calculator/models/consumption_entry.dart';
import 'package:fuel_consumption_calculator/models/service_record.dart';

void main() {
  group('Vehicle Model Tests', () {
    test('Vehicle should initialize with default oil interval', () {
      final vehicle = Vehicle(
        id: '1',
        name: 'Dacia Logan',
        initialOdometer: 1000,
        fuelType: 'Motorină',
      );

      expect(vehicle.oilEngineIntervalKm, 10000.0);
      expect(vehicle.oilGearboxIntervalKm, isNull);
    });

    test('Vehicle.fromJson should handle missing fields (Migration test)', () {
      final json = {
        'id': '1',
        'name': 'Dacia Logan',
      };

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.initialOdometer, 0.0);
      expect(vehicle.fuelType, 'Motorină');
      expect(vehicle.oilEngineIntervalKm, 10000.0);
    });
  });

  group('Odometer & Consumption Logic Tests', () {
    test('Distance calculation for first entry', () {
      final vehicle = Vehicle(id: 'v1', name: 'Car', initialOdometer: 50000.0, fuelType: 'B');
      const double currentOdo = 50450.0;
      
      final double distance = currentOdo - vehicle.initialOdometer;
      expect(distance, 450.0);
    });

    test('Distance calculation for subsequent entries', () {
      final lastEntry = ConsumptionEntry(
        id: 'e1', vehicleId: 'v1', date: DateTime.now(), 
        odometerKm: 50450.0, fuelLiters: 30, result: 6.5, fuelPricePerLiter: 20, totalCost: 600
      );
      const double currentOdo = 51000.0;
      
      final double distance = currentOdo - lastEntry.odometerKm;
      expect(distance, 550.0);
    });

    test('Price string normalization (MD format to Double)', () {
      const String priceFromAnre = "23,45";
      final double normalized = double.parse(priceFromAnre.replaceAll(',', '.'));
      expect(normalized, 23.45);
    });

    test('Total cost calculation', () {
      const double liters = 32.5;
      const double price = 21.40;
      expect(liters * price, 695.5);
    });
  });

  group('Service Record & Reminders', () {
    test('Next service calculation for Engine Oil', () {
      final vehicle = Vehicle(id: 'v1', name: 'Car', initialOdometer: 0, fuelType: 'M', oilEngineIntervalKm: 8000);
      const double currentKm = 50000.0;
      
      final double nextDue = currentKm + vehicle.oilEngineIntervalKm;
      expect(nextDue, 58000.0);
    });

    test('Next service calculation for Gearbox Oil', () {
      final vehicle = Vehicle(
        id: 'v1', name: 'Car', initialOdometer: 0, fuelType: 'M', 
        oilEngineIntervalKm: 10000, oilGearboxIntervalKm: 60000
      );
      const double currentKm = 40000.0;
      
      final double nextDue = currentKm + vehicle.oilGearboxIntervalKm!;
      expect(nextDue, 100000.0);
    });
  });
}
