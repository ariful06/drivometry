import 'dart:io';

import 'package:drivometry/core/constants/energy_type.dart';
import 'package:drivometry/core/database/schema_migrations.dart';
import 'package:drivometry/core/settings/app_settings.dart';
import 'package:drivometry/core/utils/formatters.dart';
import 'package:drivometry/features/fuel/data/models/fuel_entry_model.dart';
import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/services/fuel_consumption_calculator.dart';
import 'package:drivometry/features/fuel/domain/services/fuel_statistics.dart';
import 'package:drivometry/features/vehicles/data/models/vehicle_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

FuelEntry _fill(
  String id,
  int day,
  double odometer,
  double amount, {
  EnergyType type = EnergyType.petrol,
  bool full = true,
  double price = 100,
  double? driven,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v',
      date: DateTime(2026, 9, day),
      odometer: odometer,
      liters: amount,
      costPerLiter: price,
      totalCost: amount * price,
      isFullTank: full,
      energyType: type,
      distanceDriven: driven,
    );

/// Petrol + CNG car: the two fuels alternate on the same odometer.
final _biFuel = [
  _fill('p1', 1, 1000, 40),
  _fill('c1', 3, 1100, 8, type: EnergyType.cng, price: 50),
  _fill('c2', 6, 1300, 10, type: EnergyType.cng, price: 50, driven: 200),
  _fill('p2', 9, 1500, 30, driven: 200),
];

void main() {
  group('bi-fuel consumption', () {
    test('each fuel is its own full-to-full chain', () {
      final byId = FuelConsumptionCalculator.segmentsByEntryId(_biFuel);

      // CNG: 200 km ÷ 10 kg; petrol: 500 km ÷ 30 L.
      expect(byId['c2']!.kmPerLiter, 20);
      expect(byId['c2']!.energyType, EnergyType.cng);
      expect(byId['p2']!.kmPerLiter, closeTo(500 / 30, 1e-9));
      expect(byId['p2']!.energyType, EnergyType.petrol);
      expect(byId.containsKey('c1'), isFalse, reason: 'opens the CNG chain');
    });

    test('segments stay in chronological order across fuels', () {
      final ends = [
        for (final s in FuelConsumptionCalculator.segments(_biFuel))
          s.endEntryId,
      ];
      expect(ends, ['c2', 'p2']);
    });

    test('average can be limited to one fuel', () {
      expect(
        FuelConsumptionCalculator.averageKmPerLiter(
          _biFuel,
          energyType: EnergyType.cng,
        ),
        20,
      );
    });

    test('tank capacity only feeds gauge estimates of the main fuel', () {
      final partials = [
        _fill('c1', 1, 1000, 5, type: EnergyType.cng, full: false)
            .copyWith(fuelLevelPercent: 50),
        _fill('c2', 2, 1100, 5, type: EnergyType.cng, full: false)
            .copyWith(fuelLevelPercent: 50),
      ];
      expect(
        FuelConsumptionCalculator.segments(
          partials,
          tankCapacityLiters: 40,
          capacityEnergyType: EnergyType.petrol,
        ),
        isEmpty,
      );
      expect(
        FuelConsumptionCalculator.segments(
          partials,
          tankCapacityLiters: 10,
          capacityEnergyType: EnergyType.cng,
        ).single.kmPerLiter,
        20,
      );
    });
  });

  test('statistics are per fuel, cost per km spans all fuels', () {
    final cng = FuelStatistics.compute(
      _biFuel,
      from: DateTime(2026, 9),
      to: DateTime(2026, 9, 30),
      energyType: EnergyType.cng,
    );
    expect(cng.fillCount, 2);
    expect(cng.totalLiters, 18);
    expect(cng.averagePricePerLiter, 50);
    expect(cng.trend.single.kmPerLiter, 20);
    // (40·100 + 8·50 + 10·50 + 30·100) ÷ 400 km driven
    expect(cng.fuelCostPerKm, closeTo(7900 / 400, 1e-9));
  });

  group('storage', () {
    test('legacy fills and vehicles read as petrol', () {
      final fill = FuelEntryModel.fromMap({
        'id': 'e1',
        'vehicle_id': 'v1',
        'date': '2026-01-01T00:00:00.000',
        'odometer': 1000,
        'liters': 30,
        'cost_per_liter': 100,
        'total_cost': 3000,
      });
      expect(fill.energyType, EnergyType.petrol);

      final vehicle = VehicleModel.fromMap({
        'id': 'v1',
        'name': 'Car',
        'type': 'Car',
        'make': 'Toyota',
        'model': 'Axio',
        'year': 2020,
        'license_plate': 'X',
        'initial_odometer': 0,
        'current_odometer': 0,
        'created_at': '2026-01-01T00:00:00.000',
      }).toEntity();
      expect(vehicle.fuelType, EnergyType.petrol);
      expect(vehicle.secondaryFuelType, isNull);
      expect(vehicle.energyTypes, [EnergyType.petrol]);
    });

    test('energy types round-trip', () {
      final model = FuelEntryModel.fromEntity(
        _fill('c', 1, 1000, 8, type: EnergyType.cng),
      );
      expect(
        FuelEntryModel.fromMap(model.toMap()).energyType,
        EnergyType.cng,
      );
    });

    test('migration v2 stamps petrol once and keeps existing values', () async {
      final dir = await Directory.systemTemp.createTemp('hive_energy');
      Hive.init(dir.path);
      final fuel = await Hive.openBox<dynamic>('fuel_test');
      final vehicles = await Hive.openBox<dynamic>('vehicles_test');
      await fuel.put('a', {'id': 'a'});
      await fuel.put('b', {'id': 'b', 'energy_type': 'cng'});
      await vehicles.put('v', {'id': 'v'});

      await stampEnergyTypes(fuelEntries: fuel, vehicles: vehicles);
      await stampEnergyTypes(fuelEntries: fuel, vehicles: vehicles);

      expect((fuel.get('a') as Map)['energy_type'], 'petrol');
      expect((fuel.get('b') as Map)['energy_type'], 'cng');
      expect((vehicles.get('v') as Map)['fuel_type'], 'petrol');
      await Hive.close();
      await dir.delete(recursive: true);
    });
  });

  group('formatting', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppSettings.instance.resetForTest();
    });

    test('units follow the fuel', () {
      expect(Formatters.formatQuantity(8, EnergyType.cng), '8.00 kg');
      expect(Formatters.formatQuantity(30, EnergyType.diesel), '30.00 L');
      expect(Formatters.formatEfficiencyFor(20, EnergyType.cng), '20.00 km/kg');
      expect(
        Formatters.formatEfficiencyFor(6.5, EnergyType.electric),
        '6.50 km/kWh',
      );
      expect(Formatters.formatUnitPrice(50, EnergyType.cng), '৳ 50.00/kg');
      expect(Formatters.formatPer100(5, EnergyType.cng), '5.0 kg/100 km');
      expect(Formatters.efficiencyUnitFor(EnergyType.petrol), 'km/L');
    });

    test('gallons apply to liquid fuels only', () async {
      await AppSettings.instance.setVolumeUnit(VolumeUnit.gallon);
      expect(
          Formatters.formatQuantity(3.785411784, EnergyType.lpg), '1.00 gal');
      expect(Formatters.formatQuantity(8, EnergyType.cng), '8.00 kg');
      expect(Formatters.formatUnitPrice(1, EnergyType.petrol), '৳ 3.79/gal');
    });
  });
}
