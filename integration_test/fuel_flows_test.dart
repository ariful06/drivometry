import 'package:drivometry/core/database/hive_storage.dart';
import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/usecases/fuel_usecases.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/features/vehicles/domain/usecases/vehicle_usecases.dart';
import 'package:drivometry/injection_container.dart';
import 'package:drivometry/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the real app (Hive storage, DI, router) on a device or simulator:
/// `flutter test integration_test -d <device>`. Wipes local app data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));

  FuelEntry fill(
    String id,
    double odometer,
    double liters, {
    required bool full,
    required int daysBack,
  }) =>
      FuelEntry(
        id: id,
        vehicleId: 'it-car',
        date: daysAgo(daysBack),
        odometer: odometer,
        liters: liters,
        costPerLiter: 100,
        totalCost: liters * 100,
        isFullTank: full,
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<int> fillCount() async =>
      (await sl<GetFuelEntriesByVehicle>()('it-car')).length;

  /// Scrolls the fuel list to the fill with [id] and opens it.
  Future<void> openFill(WidgetTester tester, String id) async {
    final tile = find.byKey(Key(id));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    // Bring it to the upper part of the list, clear of the bottom bar.
    await Scrollable.ensureVisible(tester.element(tile), alignment: 0.2);
    await settle(tester);
    await tester.tap(tile);
    await settle(tester);
  }

  /// Scrolls the current form until [finder] is built and visible.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  testWidgets('fuel edit/delete, smart defaults and quick odometer',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool(app.DrivometryPrefs.hasSeenOnboarding, true);

    // main() installs its own FlutterError handler; keep the test's.
    final testOnError = FlutterError.onError;
    await app.main();
    FlutterError.onError = testOnError;
    await settle(tester);
    for (final box in [
      vehiclesBox(),
      fuelEntriesBox(),
      maintenanceEntriesBox(),
      partReplacementsBox(),
      expensesBox(),
    ]) {
      await box.clear();
    }

    await sl<AddVehicle>()(
      Vehicle(
        id: 'it-car',
        name: 'Test Axio',
        type: 'Car',
        make: 'Toyota',
        model: 'Axio',
        year: 2020,
        licensePlate: 'DHA-1',
        initialOdometer: 0,
        currentOdometer: 1500,
        createdAt: daysAgo(60),
        tankCapacityLiters: 45,
      ),
    );
    for (final entry in [
      fill('full1', 1000, 40, full: true, daysBack: 20),
      fill('partial', 1200, 10, full: false, daysBack: 15),
      fill('full2', 1500, 45, full: true, daysBack: 10),
    ]) {
      await sl<AddFuelEntry>()(entry);
    }
    await sl<RecalculateFuelConsumption>()('it-car');
    await settle(tester);

    // Open the vehicle.
    await tapText(tester, 'Test Axio');
    expect(find.text('Fuel Log'), findsOneWidget);

    // T31: quick odometer update from the header.
    await tester.tap(find.byKey(const ValueKey('update_odometer_button')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('update_odometer_field')),
      '1200',
    );
    await tapText(tester, 'Save odometer');
    expect(find.textContaining('lower than the saved reading'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('update_odometer_field')),
      '1650',
    );
    await tapText(tester, 'Save odometer');
    expect(find.textContaining('Odometer updated'), findsOneWidget);
    expect((await sl<GetVehicleById>()('it-car'))!.currentOdometer, 1650);

    // T32: new fill opens with the last price.
    await tapText(tester, 'Log Fuel');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Km since last refill *'),
      '300',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    await reveal(
      tester,
      find.widgetWithText(TextFormField, 'Cost per liter *'),
    );
    final price = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Cost per liter *'),
    );
    expect(price.controller!.text, '100');
    expect(find.textContaining('Last fill:'), findsOneWidget);
    await reveal(tester, find.text('Save entry'));
    await tapText(tester, 'Save entry');
    expect(await fillCount(), 4);
    expect((await sl<GetVehicleById>()('it-car'))!.currentOdometer, 1950);

    // T10: edit liters of the middle (partial) fill → next full tank km/L.
    await openFill(tester, 'partial');
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    expect(find.text('Edit fuel'), findsOneWidget);
    await reveal(tester, find.widgetWithText(TextFormField, 'Liters *'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Liters *'),
      '20',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    await reveal(tester, find.text('Save changes'));
    await tapText(tester, 'Save changes');
    expect(find.text('Fuel log'), findsOneWidget);

    var entries = await sl<GetFuelEntriesByVehicle>()('it-car');
    final full2 = entries.singleWhere((e) => e.id == 'full2');
    expect(full2.fuelEfficiency, closeTo(500 / 65, 1e-9));

    // T10: delete the newest fill from its detail page.
    await tester.pageBack();
    await settle(tester);
    final newest = (await sl<GetFuelEntriesByVehicle>()('it-car')).first;
    await tester.scrollUntilVisible(
      find.byKey(Key(newest.id)),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    await openFill(tester, newest.id);
    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    entries = await sl<GetFuelEntriesByVehicle>()('it-car');
    expect(entries.length, 3);
    // The deleted fill set the odometer; it falls back to the highest
    // remaining record, which includes the manual 1650 reading.
    expect((await sl<GetVehicleById>()('it-car'))!.currentOdometer, 1650);
  });
}
