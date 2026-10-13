import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:drivometry/features/fuel/domain/usecases/fuel_usecases.dart';
import 'package:drivometry/features/fuel/presentation/pages/add_fuel_entry_page.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:drivometry/features/vehicles/domain/usecases/vehicle_usecases.dart';
import 'package:drivometry/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _InMemoryFuelRepository implements FuelRepository {
  _InMemoryFuelRepository(List<FuelEntry> seed)
      : entries = {for (final e in seed) e.id: e};

  final Map<String, FuelEntry> entries;

  List<FuelEntry> _byVehicle(String vehicleId) =>
      entries.values.where((e) => e.vehicleId == vehicleId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<List<FuelEntry>> getFuelEntriesByVehicle(String vehicleId) async =>
      _byVehicle(vehicleId);

  @override
  Future<FuelEntry?> getLastFuelEntry(String vehicleId) async {
    final list = _byVehicle(vehicleId);
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<void> addFuelEntry(FuelEntry entry) async => entries[entry.id] = entry;

  @override
  Future<void> updateFuelEntry(FuelEntry entry) async =>
      entries[entry.id] = entry;

  @override
  Future<void> updateFuelEntries(List<FuelEntry> batch) async {
    for (final entry in batch) {
      entries[entry.id] = entry;
    }
  }

  @override
  Future<void> deleteFuelEntry(String id) async => entries.remove(id);

  @override
  Stream<List<FuelEntry>> watchFuelEntriesByVehicle(String vehicleId) =>
      Stream.value(_byVehicle(vehicleId));

  @override
  Future<double> getTotalFuelCostByVehicle(String vehicleId) async => 0;

  @override
  Future<double> getTotalFuelCostInRange(DateTime from, DateTime to) async => 0;

  @override
  Future<double> getTotalFuelCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  ) async =>
      0;
}

class _InMemoryVehicleRepository extends VehicleRepository {
  _InMemoryVehicleRepository(this.vehicle);
  final Vehicle vehicle;
  Vehicle? updated;

  @override
  Future<void> updateVehicle(Vehicle vehicle) async => updated = vehicle;

  @override
  Future<List<Vehicle>> getAllVehicles() async => const [];
  @override
  Future<Vehicle?> getVehicleById(String id) async => updated ?? vehicle;
  @override
  Future<void> addVehicle(Vehicle vehicle) async {}
  @override
  Future<void> deleteVehicle(String id) async {}
  @override
  Stream<List<Vehicle>> watchAllVehicles() => const Stream.empty();
}

Vehicle _vehicle({double? tankCapacity = 45, double odometer = 1200}) =>
    Vehicle(
      id: 'v1',
      name: 'Test car',
      type: 'Car',
      make: 'Toyota',
      model: 'Axio',
      year: 2020,
      licensePlate: 'DHA-1',
      initialOdometer: 0,
      currentOdometer: odometer,
      createdAt: DateTime(2026),
      tankCapacityLiters: tankCapacity,
    );

FuelEntry _saved(
  String id,
  double odometer,
  double liters, {
  required bool full,
  required int day,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: DateTime(2026, 9, day),
      odometer: odometer,
      liters: liters,
      costPerLiter: 100,
      totalCost: liters * 100,
      isFullTank: full,
    );

late _InMemoryFuelRepository fuelRepo;
late _InMemoryVehicleRepository vehicleRepo;

Future<void> _registerFakes(List<FuelEntry> seed, Vehicle vehicle) async {
  await sl.reset();
  fuelRepo = _InMemoryFuelRepository(seed);
  vehicleRepo = _InMemoryVehicleRepository(vehicle);
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
}) async {
  await _registerFakes(history, vehicle);
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
    _saved('full1', 1000, 40, full: true, day: 1),
    _saved('partial', 1200, 10, full: false, day: 5),
  ];

  testWidgets('full tank uses vehicle tank capacity, no liters input',
      (tester) async {
    await _pumpPage(tester, _vehicle(), history: history);

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
    await _pumpPage(tester, _vehicle(), history: history);

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
    await _pumpPage(tester, _vehicle(), history: history);

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
    await _pumpPage(tester, _vehicle(tankCapacity: null), history: history);

    expect(_field('Liters *'), findsOneWidget);
    expect(find.text('No tank capacity saved for this vehicle'), findsOneWidget);
  });

  testWidgets('first log for a vehicle asks for odometer and saves full tank',
      (tester) async {
    await _pumpPage(tester, _vehicle(odometer: 0), history: const []);

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
    await _pumpPage(tester, _vehicle(), history: history);

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
      _vehicle(tankCapacity: 50, odometer: 1000),
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
}
