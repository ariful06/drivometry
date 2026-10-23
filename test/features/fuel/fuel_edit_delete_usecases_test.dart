import 'package:drivometry/core/utils/odometer_validator.dart';
import 'package:drivometry/features/fuel/domain/usecases/fuel_usecases.dart';
import 'package:drivometry/features/maintenance/domain/entities/maintenance_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fuel_test_fakes.dart';

void main() {
  group('OdometerValidator.resolveCurrent', () {
    test('falls back to highest remaining when the changed record set it', () {
      expect(
        OdometerValidator.resolveCurrent(
          current: 1500,
          initial: 0,
          remaining: const [1000, 1200],
          replacedOdometer: 1500,
        ),
        1200,
      );
    });

    test('keeps a reading raised by something else', () {
      expect(
        OdometerValidator.resolveCurrent(
          current: 1800,
          initial: 0,
          remaining: const [1000, 1200],
          replacedOdometer: 1500,
        ),
        1800,
      );
    });

    test('rises to an edited reading above current', () {
      expect(
        OdometerValidator.resolveCurrent(
          current: 1500,
          initial: 0,
          remaining: const [1000, 1650],
          replacedOdometer: 1500,
        ),
        1650,
      );
    });

    test('never drops below the initial odometer', () {
      expect(
        OdometerValidator.resolveCurrent(
          current: 1000,
          initial: 900,
          remaining: const [],
          replacedOdometer: 1000,
        ),
        900,
      );
    });
  });

  group('edit and delete fuel entries', () {
    late InMemoryFuelRepository fuelRepo;
    late InMemoryVehicleRepository vehicleRepo;
    late EditFuelEntry edit;
    late RemoveFuelEntry remove;

    void setUpRepos({List<MaintenanceEntry> maintenance = const []}) {
      fuelRepo = InMemoryFuelRepository([
        savedFill('full1', 1000, 40, full: true, day: 1),
        savedFill('partial', 1200, 10, full: false, day: 5),
        savedFill('full2', 1500, 45, full: true, day: 9),
      ]);
      vehicleRepo = InMemoryVehicleRepository(testVehicle(odometer: 1500));
      final recalculate = RecalculateFuelConsumption(fuelRepo, vehicleRepo);
      final sync = SyncVehicleOdometer(
        fuelRepo,
        InMemoryMaintenanceRepository(maintenance),
        vehicleRepo,
      );
      edit = EditFuelEntry(fuelRepo, recalculate, sync);
      remove = RemoveFuelEntry(fuelRepo, recalculate, sync);
    }

    MaintenanceEntry service(double odometer) => MaintenanceEntry(
          id: 'm1',
          vehicleId: 'v1',
          type: 'Oil change',
          title: 'Oil change',
          description: '',
          cost: 0,
          odometer: odometer,
          serviceDate: DateTime(2026, 9, 7),
        );

    test('editing liters of a middle fill updates the next full tank km/L',
        () async {
      setUpRepos();
      await edit(fuelRepo.entries['partial']!.copyWith(liters: 20));

      // 500 km ÷ (20 L partial + 45 L full)
      expect(
        fuelRepo.entries['full2']!.fuelEfficiency,
        closeTo(500 / 65, 1e-9),
      );
      expect(fuelRepo.entries['partial']!.fuelEfficiency, isNull);
      expect(vehicleRepo.updated, isNull, reason: 'odometer unchanged');
    });

    test('lowering the latest odometer lowers the vehicle odometer', () async {
      setUpRepos();
      await edit(fuelRepo.entries['full2']!.copyWith(odometer: 1400));

      expect(vehicleRepo.updated?.currentOdometer, 1400);
      expect(
        fuelRepo.entries['full2']!.fuelEfficiency,
        closeTo(400 / 55, 1e-9),
      );
    });

    test('deleting the latest fill falls back to the highest record', () async {
      setUpRepos(maintenance: [service(1300)]);
      await remove(fuelRepo.entries['full2']!);

      expect(fuelRepo.entries.containsKey('full2'), isFalse);
      expect(vehicleRepo.updated?.currentOdometer, 1300);
    });

    test('deleting a middle fill keeps the odometer and re-chains', () async {
      setUpRepos();
      await remove(fuelRepo.entries['partial']!);

      expect(vehicleRepo.updated, isNull);
      // Now full-to-full: 500 km ÷ 45 L.
      expect(
        fuelRepo.entries['full2']!.fuelEfficiency,
        closeTo(500 / 45, 1e-9),
      );
    });
  });
}
