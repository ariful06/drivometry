import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:drivometry/features/analytics/presentation/pages/analytics_page.dart';
import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:drivometry/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:drivometry/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFuel extends Mock implements FuelRepository {}

class _MockMaintenance extends Mock implements MaintenanceRepository {}

class _MockVehicles extends Mock implements VehicleRepository {}

Vehicle _vehicle(String id, String name) => Vehicle(
      id: id,
      name: name,
      type: 'car',
      make: 'Toyota',
      model: 'Axio',
      year: 2020,
      licensePlate: id,
      initialOdometer: 0,
      currentOdometer: 1000,
      createdAt: DateTime(2024),
    );

void main() {
  late _MockFuel fuel;
  late _MockMaintenance maintenance;
  late _MockVehicles vehicles;

  setUp(() async {
    fuel = _MockFuel();
    maintenance = _MockMaintenance();
    vehicles = _MockVehicles();
    when(() => vehicles.getAllVehicles()).thenAnswer(
        (_) async => [_vehicle('a', 'Car A'), _vehicle('b', 'Car B')]);
    when(() => fuel.getFuelEntriesByVehicle(any())).thenAnswer((_) async => []);
    when(() => fuel.getTotalFuelCostByVehicleInRange('a', any(), any()))
        .thenAnswer((_) async => 1000);
    when(() => fuel.getTotalFuelCostByVehicleInRange('b', any(), any()))
        .thenAnswer((_) async => 500);
    when(() => maintenance.getTotalMaintenanceCostByVehicleInRange(
        'a', any(), any())).thenAnswer((_) async => 200);
    when(() => maintenance.getTotalMaintenanceCostByVehicleInRange(
        'b', any(), any())).thenAnswer((_) async => 300);
    when(() => fuel.getTotalFuelCostInRange(any(), any()))
        .thenAnswer((_) async => 1500);
    when(() => maintenance.getTotalMaintenanceCostInRange(any(), any()))
        .thenAnswer((_) async => 500);
    await sl.reset();
    sl.registerFactory(() => AnalyticsCubit(
          fuelRepository: fuel,
          maintenanceRepository: maintenance,
          vehicleRepository: vehicles,
        ));
  });

  tearDown(() => sl.reset());

  test('total cost is fuel + maintenance and never negative', () async {
    final cubit = sl<AnalyticsCubit>();
    await cubit.loadAnalytics(period: 'Monthly');
    final state = cubit.state as AnalyticsLoaded;
    expect(state.totalFuelCost, 1500);
    expect(state.totalMaintenanceCost, 500);
    expect(state.totalCost, 2000);
    expect(state.vehicleAnalytics.map((v) => v.totalCost), [1200, 800]);
  });

  test('cost per km only counts distance driven inside the period', () async {
    final now = DateTime.now();
    FuelEntry entry(String id, DateTime date, double km) => FuelEntry(
          id: id,
          vehicleId: 'a',
          date: date,
          odometer: 1000,
          liters: 10,
          costPerLiter: 100,
          totalCost: 1000,
          distanceDriven: km,
        );
    when(() => fuel.getFuelEntriesByVehicle('a')).thenAnswer((_) async => [
          entry('old', DateTime(now.year - 2), 5000),
          entry('new', now, 100),
        ]);
    final cubit = sl<AnalyticsCubit>();
    await cubit.loadAnalytics(period: 'Monthly', vehicleId: 'a');
    final data = (cubit.state as AnalyticsLoaded).vehicleAnalytics.single;
    expect(data.totalDistanceKm, 100);
    expect(data.costPerKm, 12);
  });

  testWidgets('shows total, per-vehicle costs and charts', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const AnalyticsPage(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Total cost'), findsOneWidget);
    expect(find.textContaining(RegExp(r'-\s*\S?\d')), findsNothing);
    final list = find.descendant(
        of: find.byType(ListView), matching: find.byType(Scrollable));
    for (final label in ['Cost Breakdown', 'Cost by vehicle', 'Car B']) {
      await tester.scrollUntilVisible(find.text(label), 300,
          scrollable: list.first);
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('Rental'), findsNothing);
  });
}
