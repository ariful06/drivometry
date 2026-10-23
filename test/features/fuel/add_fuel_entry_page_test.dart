import 'package:drivometry/core/constants/energy_type.dart';
import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/usecases/fuel_usecases.dart';
import 'package:drivometry/features/fuel/presentation/pages/add_fuel_entry_page.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/features/vehicles/domain/usecases/vehicle_usecases.dart';
import 'package:drivometry/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fuel_test_fakes.dart';

late InMemoryFuelRepository fuelRepo;
late InMemoryVehicleRepository vehicleRepo;

Future<void> _registerFakes(
  List<FuelEntry> seed,
  Vehicle vehicle, {
  bool keepPreferences = false,
}) async {
  await sl.reset();
  if (!keepPreferences) SharedPreferences.setMockInitialValues({});
  fuelRepo = InMemoryFuelRepository(seed);
  vehicleRepo = InMemoryVehicleRepository(vehicle);
  sl
    ..registerSingleton(GetLastFuelEntry(fuelRepo))
    ..registerSingleton(GetFuelEntriesByVehicle(fuelRepo))
    ..registerSingleton(AddFuelEntry(fuelRepo))
    ..registerSingleton(RecalculateFuelConsumption(fuelRepo, vehicleRepo))
    ..registerSingleton(UpdateVehicle(vehicleRepo));
}

Future<void> _pumpPage(
  WidgetTester tester,
  Vehicle vehicle, {
  List<FuelEntry> history = const [],
  bool keepPreferences = false,
}) async {
  await _registerFakes(history, vehicle, keepPreferences: keepPreferences);
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold()),
      GoRoute(
        path: '/add',
        builder: (_, __) => AddFuelEntryPage(vehicle: vehicle),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
  router.push('/add');
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save entry'));
  await tester.pumpAndSettle();
}

void main() {
  final history = [
    savedFill('full1', 1000, 40, full: true, day: 1),
    savedFill('partial', 1200, 10, full: false, day: 5),
  ];

  testWidgets('full tank uses vehicle tank capacity, no liters input',
      (tester) async {
    await _pumpPage(tester, testVehicle(), history: history);

    expect(_field('Liters *'), findsNothing);
    expect(find.text('Full tank (from vehicle)'), findsOneWidget);
    expect(find.text('45 L'), findsOneWidget);

    await tester.enterText(_field('Km since last refill *'), '300');
    await tester.enterText(_field('Cost per liter *'), '100');
    await tester.pump();

    expect(find.text('৳ 4,500.00'), findsOneWidget);
    // (1500 - 1000) km ÷ (10 L partial + 45 L full) = 9.09 km/L
    expect(find.text('Consumption since last full tank'), findsOneWidget);
    expect(find.textContaining('9.09'), findsOneWidget);

    await _save(tester);

    final saved = fuelRepo.entries.values
        .singleWhere((e) => e.id != 'full1' && e.id != 'partial');
    expect(saved.liters, 45);
    expect(saved.totalCost, 4500);
    expect(saved.isFullTank, isTrue);
    expect(saved.odometer, 1500);
    expect(saved.fuelEfficiency, closeTo(500 / 55, 1e-9));
    expect(vehicleRepo.updated?.currentOdometer, 1500);
  });

  testWidgets('partial fill asks for liters and stores no consumption',
      (tester) async {
    await _pumpPage(tester, testVehicle(), history: history);

    await tester.tap(find.text('Full tank'));
    await tester.pumpAndSettle();
    expect(_field('Liters *'), findsOneWidget);

    await tester.enterText(_field('Km since last refill *'), '150');
    await tester.enterText(_field('Liters *'), '20');
    await tester.enterText(_field('Cost per liter *'), '100');
    await tester.pump();
    expect(find.text('৳ 2,000.00'), findsOneWidget);

    await _save(tester);

    final saved = fuelRepo.entries.values
        .singleWhere((e) => e.id != 'full1' && e.id != 'partial');
    expect(saved.liters, 20);
    expect(saved.totalCost, 2000);
    expect(saved.isFullTank, isFalse);
    expect(saved.fuelEfficiency, isNull);
  });

  testWidgets('partial fill can be entered by total paid', (tester) async {
    await _pumpPage(tester, testVehicle(), history: history);

    await tester.tap(find.text('Full tank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Total paid'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Km since last refill *'), '150');
    await tester.enterText(_field('Total paid *'), '1500');
    await tester.enterText(_field('Cost per liter *'), '100');
    await _save(tester);

    final saved = fuelRepo.entries.values
        .singleWhere((e) => e.id != 'full1' && e.id != 'partial');
    expect(saved.liters, 15);
    expect(saved.totalCost, 1500);
  });

  testWidgets('full tank without saved capacity falls back to liters input',
      (tester) async {
    await _pumpPage(tester, testVehicle(tankCapacity: null), history: history);

    expect(_field('Liters *'), findsOneWidget);
    expect(
        find.text('No tank capacity saved for this vehicle'), findsOneWidget);
  });

  testWidgets('first log for a vehicle asks for odometer and saves full tank',
      (tester) async {
    await _pumpPage(tester, testVehicle(odometer: 0), history: const []);

    await tester.enterText(_field('Odometer (km) *'), '800');
    await tester.enterText(_field('Cost per liter *'), '100');
    await _save(tester);

    final saved = fuelRepo.entries.values.single;
    expect(saved.odometer, 800);
    expect(saved.liters, 45);
    expect(saved.isFullTank, isTrue);
    expect(saved.fuelEfficiency, isNull);
  });

  testWidgets('full tank uses pumped liters when entered', (tester) async {
    await _pumpPage(tester, testVehicle(), history: history);

    await tester.enterText(_field('Km since last refill *'), '300');
    await tester.enterText(_field('Liters pumped (optional)'), '30');
    await tester.enterText(_field('Cost per liter *'), '100');
    await tester.pump();
    expect(find.text('৳ 3,000.00'), findsOneWidget);

    await _save(tester);

    final saved = fuelRepo.entries.values
        .singleWhere((e) => e.id != 'full1' && e.id != 'partial');
    expect(saved.liters, 30);
    // 500 km ÷ (10 L partial + 30 L) = 12.5 km/L
    expect(saved.fuelEfficiency, closeTo(12.5, 1e-9));
  });

  testWidgets('partial fill with fuel level saves level and estimates',
      (tester) async {
    // Only a partial so far → no full-tank baseline.
    final partialsOnly = [
      FuelEntry(
        id: 'p0',
        vehicleId: 'v1',
        date: DateTime(2026, 9, 1),
        odometer: 1000,
        liters: 20,
        costPerLiter: 100,
        totalCost: 2000,
        fuelLevelPercent: 60,
      ),
    ];
    await _pumpPage(
      tester,
      testVehicle(tankCapacity: 50, odometer: 1000),
      history: partialsOnly,
    );

    await tester.tap(find.text('Full tank'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Km since last refill *'), '300');
    await tester.enterText(_field('Liters *'), '20');
    await tester.enterText(_field('Fuel level after fill (optional)'), '80');
    await tester.enterText(_field('Cost per liter *'), '100');
    await tester.pump();

    // used = 50×60% + 20 − 50×80% = 10 L → 30 km/L
    expect(find.text('Estimated consumption (fuel gauge)'), findsOneWidget);

    await _save(tester);

    final saved = fuelRepo.entries.values.singleWhere((e) => e.id != 'p0');
    expect(saved.fuelLevelPercent, 80);
    expect(saved.isFullTank, isFalse);
    expect(saved.fuelEfficiency, closeTo(30, 1e-9));
  });

  testWidgets('new fill prefills price from the last fill', (tester) async {
    await _pumpPage(tester, testVehicle(), history: history);

    final price = tester.widget<TextFormField>(_field('Cost per liter *'));
    expect(price.controller!.text, '100');
    expect(find.textContaining('Last fill:'), findsOneWidget);
  });

  testWidgets('next fill reopens in the modes the last one used',
      (tester) async {
    await _pumpPage(tester, testVehicle(), history: history);

    // Log a partial fill by odometer and total paid.
    await tester.tap(find.text('Full odometer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full tank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Total paid'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Odometer (km) *'), '1350');
    await tester.enterText(_field('Total paid *'), '1500');
    await _save(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('fuel_form_trip_mode_v1'), isFalse);
    expect(prefs.getBool('fuel_form_total_paid_v1'), isTrue);
  });

  testWidgets('remembered modes are restored on the next fill', (tester) async {
    await _pumpPage(tester, testVehicle(tankCapacity: null), history: history);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fuel_form_trip_mode_v1', false);
    await prefs.setBool('fuel_form_total_paid_v1', true);

    await _pumpPage(
      tester,
      testVehicle(tankCapacity: null),
      history: history,
      keepPreferences: true,
    );

    expect(find.byKey(const ValueKey('fuel_full_odo_field')), findsOneWidget);
    expect(_field('Total paid *'), findsOneWidget);
  });

  testWidgets('bi-fuel vehicle logs a CNG fill in kg at the last CNG price',
      (tester) async {
    final biFuel = testVehicle().copyWith(secondaryFuelType: EnergyType.cng);
    await _pumpPage(
      tester,
      biFuel,
      history: [
        ...history,
        FuelEntry(
          id: 'cng0',
          vehicleId: 'v1',
          date: DateTime(2026, 9, 3),
          odometer: 1100,
          liters: 8,
          costPerLiter: 45,
          totalCost: 360,
          isFullTank: true,
          energyType: EnergyType.cng,
        ),
      ],
    );

    // Opens on the main fuel at the last petrol price.
    expect(find.text('Petrol'), findsOneWidget);
    expect(_field('Cost per liter *'), findsOneWidget);

    await tester.tap(find.text('CNG'));
    await tester.pumpAndSettle();

    // CNG has no saved capacity, so the amount is typed in kg.
    expect(find.text('Full tank (from vehicle)'), findsNothing);
    expect(_field('Kilograms *'), findsOneWidget);
    final price = tester.widget<TextFormField>(_field('Cost per kg *'));
    expect(price.controller!.text, '45');

    await tester.enterText(_field('Km since last refill *'), '300');
    await tester.enterText(_field('Kilograms *'), '10');
    await _save(tester);

    final saved = fuelRepo.entries.values.singleWhere(
      (e) => !['full1', 'partial', 'cng0'].contains(e.id),
    );
    expect(saved.energyType, EnergyType.cng);
    expect(saved.liters, 10);
    expect(saved.totalCost, 450);
    // CNG chain: 1500 - 1100 km ÷ 10 kg.
    expect(saved.fuelEfficiency, closeTo(40, 1e-9));
  });
}
