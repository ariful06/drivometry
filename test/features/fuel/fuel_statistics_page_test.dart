import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:drivometry/features/fuel/presentation/pages/fuel_statistics_page.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFuel extends Mock implements FuelRepository {}

final _vehicle = Vehicle(
  id: 'v',
  name: 'Axio',
  type: 'car',
  make: 'Toyota',
  model: 'Axio',
  year: 2020,
  licensePlate: 'X',
  initialOdometer: 0,
  currentOdometer: 5000,
  createdAt: DateTime(2024),
);

FuelEntry _fill(int i) {
  final date = DateTime.now().subtract(Duration(days: 30 * (6 - i)));
  return FuelEntry(
    id: 'f$i',
    vehicleId: 'v',
    date: date,
    odometer: 1000.0 + i * 400,
    liters: 40,
    costPerLiter: 100 + i.toDouble(),
    totalCost: 40 * (100 + i.toDouble()),
    isFullTank: true,
    distanceDriven: i == 0 ? null : 400,
  );
}

Future<void> _pump(WidgetTester tester, List<FuelEntry> entries) async {
  final fuel = _MockFuel();
  when(() => fuel.getFuelEntriesByVehicle('v'))
      .thenAnswer((_) async => entries);
  await sl.reset();
  sl.registerSingleton<FuelRepository>(fuel);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: FuelStatisticsPage(vehicle: _vehicle),
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => sl.reset());

  testWidgets('empty state', (tester) async {
    await _pump(tester, []);
    expect(find.text('No fuel entries in this range'), findsOneWidget);
  });

  testWidgets('single fill shows summary but no trend', (tester) async {
    await _pump(tester, [_fill(5)]);
    expect(find.text('Fuel spend'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Not enough fills yet'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Not enough fills yet'), findsOneWidget);
  });

  testWidgets('many fills render charts and best/worst', (tester) async {
    await _pump(tester, [for (var i = 0; i < 6; i++) _fill(i)]);
    expect(find.text('Best economy'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Economy trend'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Monthly fuel spend'), findsOneWidget);
    expect(find.text('Economy trend'), findsOneWidget);
  });
}
