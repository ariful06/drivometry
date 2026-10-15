import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:drivometry/features/analytics/presentation/pages/analytics_page.dart';
import 'package:drivometry/features/expenses/domain/entities/expense.dart';
import 'package:drivometry/features/expenses/domain/repositories/expense_repository.dart';
import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:drivometry/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:drivometry/features/parts/domain/entities/part_replacement.dart';
import 'package:drivometry/features/parts/domain/repositories/part_replacement_repository.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:drivometry/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFuel extends Mock implements FuelRepository {}

class _MockMaintenance extends Mock implements MaintenanceRepository {}

class _MockVehicles extends Mock implements VehicleRepository {}

class _MockExpenses extends Mock implements ExpenseRepository {}

class _MockParts extends Mock implements PartReplacementRepository {}

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
  late _MockExpenses expenses;
  late _MockParts parts;

  setUp(() async {
    fuel = _MockFuel();
    maintenance = _MockMaintenance();
    vehicles = _MockVehicles();
    expenses = _MockExpenses();
    parts = _MockParts();
    PartReplacement part(
            String id, String vehicle, double? cost, DateTime? installed) =>
        PartReplacement(
          id: id,
          vehicleId: vehicle,
          partName: 'Part $id',
          installOdometer: 0,
          cost: cost,
          installedAt: installed,
        );
    when(() => parts.getByVehicle('a')).thenAnswer((_) async => [
          part('p1', 'a', 300, DateTime.now()),
          part('old', 'a', 7777, DateTime(2001)), // outside the period
          part('nodate', 'a', 5555, null), // undated: not counted
        ]);
    when(() => parts.getByVehicle('b')).thenAnswer((_) async => []);
    when(() => expenses.getAll()).thenAnswer((_) async => [
          Expense(
            id: 'e1',
            vehicleId: 'a',
            date: DateTime.now(),
            category: ExpenseCategory.insurance,
            amount: 400,
          ),
          Expense(
            id: 'e2',
            vehicleId: 'b',
            date: DateTime.now(),
            category: ExpenseCategory.parking,
            amount: 100,
          ),
          Expense(
            id: 'old',
            vehicleId: 'a',
            date: DateTime(2001),
            category: ExpenseCategory.tax,
            amount: 9999,
          ),
        ]);
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
          expenseRepository: expenses,
          partRepository: parts,
        ));
  });

  tearDown(() => sl.reset());

  test('total cost is fuel + maintenance and never negative', () async {
    final cubit = sl<AnalyticsCubit>();
    await cubit.loadAnalytics(period: 'Monthly');
    final state = cubit.state as AnalyticsLoaded;
    expect(state.totalFuelCost, 1500);
    expect(state.totalMaintenanceCost, 500);
    expect(state.totalOtherCost, 500); // old 2001 expense is out of range
    expect(state.totalPartsCost, 300);
    expect(state.totalCost, 2800);
    expect(state.vehicleAnalytics.map((v) => v.otherCost), [400, 100]);
    expect(state.vehicleAnalytics.map((v) => v.partsCost), [300, 0]);
    expect(state.vehicleAnalytics.map((v) => v.totalCost), [1900, 900]);
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
    // (1000 fuel + 200 maintenance + 300 parts + 400 other) / 100 km
    expect(data.costPerKm, 19);
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
    expect(find.text('Other expenses'), findsWidgets);
    expect(find.text('Parts'), findsWidgets);
  });
}
