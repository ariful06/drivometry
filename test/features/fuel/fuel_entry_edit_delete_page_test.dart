import 'dart:async';

import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/usecases/fuel_usecases.dart';
import 'package:drivometry/features/fuel/presentation/pages/add_fuel_entry_page.dart';
import 'package:drivometry/features/fuel/presentation/pages/fuel_entry_detail_page.dart';
import 'package:drivometry/features/vehicles/domain/usecases/vehicle_usecases.dart';
import 'package:drivometry/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fuel_test_fakes.dart';

late InMemoryFuelRepository fuelRepo;
late InMemoryVehicleRepository vehicleRepo;

Future<void> _pumpDetail(WidgetTester tester, String entryId) async {
  await sl.reset();
  fuelRepo = InMemoryFuelRepository([
    savedFill('full1', 1000, 40, full: true, day: 1),
    savedFill('partial', 1200, 10, full: false, day: 5),
    savedFill('full2', 1500, 45, full: true, day: 9),
  ]);
  vehicleRepo = InMemoryVehicleRepository(testVehicle(odometer: 1500));
  final recalculate = RecalculateFuelConsumption(fuelRepo, vehicleRepo);
  final sync = SyncVehicleOdometer(
    fuelRepo,
    InMemoryMaintenanceRepository(),
    vehicleRepo,
  );
  sl
    ..registerSingleton(GetVehicleById(vehicleRepo))
    ..registerSingleton(GetFuelEntriesByVehicle(fuelRepo))
    ..registerSingleton(EditFuelEntry(fuelRepo, recalculate, sync))
    ..registerSingleton(RemoveFuelEntry(fuelRepo, recalculate, sync));

  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold()),
      GoRoute(
        path: '/vehicles/:vehicleId/fuel/:entryId/edit',
        builder: (_, state) {
          final args = state.extra! as FuelEntryEditArgs;
          return AddFuelEntryPage(
            vehicle: args.vehicle,
            initialEntry: args.entry,
          );
        },
      ),
      GoRoute(
        path: '/vehicles/:vehicleId/fuel/:entryId',
        builder: (_, state) => FuelEntryDetailPage(
          args: state.extra! as FuelEntryDetailArgs,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
  unawaited(
    router.push(
      '/vehicles/v1/fuel/$entryId',
      extra: FuelEntryDetailArgs(entry: fuelRepo.entries[entryId]!),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

FuelEntry? get _full2 => fuelRepo.entries['full2'];

void main() {
  testWidgets('editing liters of a middle fill updates next full tank km/L',
      (tester) async {
    await _pumpDetail(tester, 'partial');

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit fuel'), findsOneWidget);
    // Prefilled from the saved partial fill, odometer measured from full1.
    expect(find.widgetWithText(TextFormField, '10'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '1200'), findsOneWidget);

    await tester.enterText(_field('Liters *'), '20');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final edited = fuelRepo.entries['partial']!;
    expect(edited.liters, 20);
    expect(edited.totalCost, 2000);
    expect(edited.odometer, 1200);
    expect(fuelRepo.entries.length, 3, reason: 'edited in place');
    // 500 km ÷ (20 L partial + 45 L full)
    expect(_full2!.fuelEfficiency, closeTo(500 / 65, 1e-9));
    expect(vehicleRepo.updated, isNull);

    // Back on the detail page, showing the reloaded fill.
    expect(find.text('Fuel log'), findsOneWidget);
    expect(find.textContaining('2,000'), findsWidgets);
  });

  testWidgets('edit rejects an odometer above the next fill', (tester) async {
    await _pumpDetail(tester, 'partial');
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Odometer (km) *'), '1600');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('higher than a later reading'), findsOneWidget);
    expect(fuelRepo.entries['partial']!.odometer, 1200);
  });

  testWidgets('delete asks for confirmation, then recalculates',
      (tester) async {
    await _pumpDetail(tester, 'full2');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete fuel entry?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_full2, isNotNull);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(_full2, isNull);
    // Vehicle odometer falls back to the highest remaining fill.
    expect(vehicleRepo.updated?.currentOdometer, 1200);
    expect(find.text('Fuel entry deleted'), findsOneWidget);
    expect(find.text('Fuel log'), findsNothing);
  });
}
