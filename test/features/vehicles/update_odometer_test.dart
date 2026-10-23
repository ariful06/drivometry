import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/core/utils/odometer_validator.dart';
import 'package:drivometry/features/maintenance/domain/entities/maintenance_entry.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/features/vehicles/domain/usecases/vehicle_usecases.dart';
import 'package:drivometry/features/vehicles/presentation/widgets/update_odometer_sheet.dart';
import 'package:drivometry/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fuel/fuel_test_fakes.dart';

late InMemoryVehicleRepository vehicleRepo;
late int reminderChecks;

UpdateVehicleOdometer _useCase(
    {List<MaintenanceEntry> maintenance = const []}) {
  vehicleRepo = InMemoryVehicleRepository(testVehicle(odometer: 1500));
  reminderChecks = 0;
  return UpdateVehicleOdometer(
    vehicleRepo,
    InMemoryFuelRepository([
      savedFill('f1', 1000, 40, full: true, day: 1),
      savedFill('f2', 1500, 45, full: true, day: 9),
    ]),
    InMemoryMaintenanceRepository(maintenance),
    onUpdated: () async => reminderChecks++,
  );
}

void main() {
  group('UpdateVehicleOdometer', () {
    test('accepts a higher reading and runs reminder checks', () async {
      final update = _useCase();
      final vehicle = testVehicle(odometer: 1500);

      expect(await update.check(vehicle, 1800), isNull);
      final saved = await update(vehicle, 1800);

      expect(saved.currentOdometer, 1800);
      expect(vehicleRepo.updated?.currentOdometer, 1800);
      expect(reminderChecks, 1);
    });

    test('rejects a reading below the saved odometer', () async {
      final check = await _useCase().check(testVehicle(odometer: 1500), 1400);
      expect(check?.issue, OdometerIssue.error);
    });

    test('rejects a reading below a maintenance record', () async {
      final update = _useCase(
        maintenance: [
          MaintenanceEntry(
            id: 'm1',
            vehicleId: 'v1',
            type: 'Oil change',
            title: 'Oil change',
            description: '',
            cost: 0,
            odometer: 1700,
            serviceDate: DateTime(2026, 9, 12),
          ),
        ],
      );
      final check = await update.check(testVehicle(odometer: 1500), 1600);
      expect(check?.issue, OdometerIssue.error);
    });

    test('warns on an implausible jump', () async {
      final check = await _useCase().check(testVehicle(odometer: 1500), 9000);
      expect(check?.issue, OdometerIssue.warning);
    });
  });

  group('UpdateOdometerSheet', () {
    Vehicle? result;

    Future<void> pumpSheet(WidgetTester tester) async {
      await sl.reset();
      sl.registerSingleton(_useCase());
      result = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showUpdateOdometerSheet(
                  context,
                  testVehicle(odometer: 1500),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Finder field() => find.byKey(const ValueKey('update_odometer_field'));

    testWidgets('saves a valid reading and returns the vehicle',
        (tester) async {
      await pumpSheet(tester);
      expect(find.text('Update odometer'), findsOneWidget);

      await tester.enterText(field(), '1650');
      await tester.tap(find.text('Save odometer'));
      await tester.pumpAndSettle();

      expect(find.text('Update odometer'), findsNothing);
      expect(result?.currentOdometer, 1650);
      expect(vehicleRepo.updated?.currentOdometer, 1650);
    });

    testWidgets('shows the error and keeps the sheet open for a lower reading',
        (tester) async {
      await pumpSheet(tester);

      await tester.enterText(field(), '1200');
      await tester.tap(find.text('Save odometer'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('lower than the saved reading'), findsOneWidget);
      expect(vehicleRepo.updated, isNull);
      expect(result, isNull);
    });

    testWidgets('asks before saving a big jump', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(field(), '9000');
      await tester.tap(find.text('Save odometer'));
      await tester.pumpAndSettle();
      expect(find.text('Check odometer'), findsOneWidget);

      await tester.tap(find.text('Save anyway'));
      await tester.pumpAndSettle();
      expect(vehicleRepo.updated?.currentOdometer, 9000);
    });
  });
}
