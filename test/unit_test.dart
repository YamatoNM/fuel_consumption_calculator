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
        // initialOdometer and fuelType are missing in old data
      };

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.initialOdometer, 0.0);
      expect(vehicle.fuelType, 'Motorină');
      expect(vehicle.oilEngineIntervalKm, 10000.0);
    });
  });

  group('Consumption Logic Tests', () {
    test('Fuel consumption calculation formula', () {
      const double fuel = 32.0;
      const double distance = 450.0;
      
      // Formula: (liters / km) * 100
      final double result = (fuel / distance) * 100;
      
      expect(result.toStringAsFixed(2), '7.11');
    });

    test('ConsumptionEntry.fromJson should map all fields correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'e1',
        'vehicleId': 'v1',
        'date': now.toIso8601String(),
        'odometerKm': 1500.0,
        'fuelLiters': 30.0,
        'result': 6.5,
        'fuelPricePerLiter': 23.5,
        'totalCost': 705.0,
      };

      final entry = ConsumptionEntry.fromJson(json);

      expect(entry.odometerKm, 1500.0);
      expect(entry.totalCost, 705.0);
      expect(entry.fuelPricePerLiter, 23.5);
    });
  });

  group('Service Record Tests', () {
    test('ServiceType enum should support gearbox oil', () {
      expect(ServiceType.uleiCutie.name, 'uleiCutie');
    });

    test('ServiceRecord should parse correctly from JSON', () {
      final json = {
        'id': 's1',
        'vehicleId': 'v1',
        'date': DateTime.now().toIso8601String(),
        'odometerKm': 50000.0,
        'type': 'uleiMotor',
        'description': 'Schimb ulei iarna',
        'cost': 1200.0,
      };

      final record = ServiceRecord.fromJson(json);

      expect(record.type, ServiceType.uleiMotor);
      expect(record.cost, 1200.0);
    });
  });
}
