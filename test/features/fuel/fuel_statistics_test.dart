import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/services/fuel_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

FuelEntry _fill(
  String id,
  DateTime date,
  double odo,
  double liters,
  double cost, {
  bool full = true,
  double? driven,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v',
      date: date,
      odometer: odo,
      liters: liters,
      costPerLiter: cost / liters,
      totalCost: cost,
      isFullTank: full,
      distanceDriven: driven,
    );

void main() {
  final from = DateTime(2026);
  final to = DateTime(2026, 12, 31);

  test('empty history gives empty statistics', () {
    final s = FuelStatistics.compute([], from: from, to: to);
    expect(s.isEmpty, isTrue);
    expect(s.averagePricePerLiter, isNull);
    expect(s.fuelCostPerKm, isNull);
    expect(s.trend, isEmpty);
  });

  test('average price is liter-weighted, not a mean of unit prices', () {
    final s = FuelStatistics.compute([
      _fill('a', DateTime(2026, 1, 5), 1000, 10, 1000), // 100/L
      _fill('b', DateTime(2026, 1, 20), 1200, 40, 5200, driven: 200), // 130/L
    ], from: from, to: to);
    expect(s.totalLiters, 50);
    expect(s.totalCost, 6200);
    expect(s.averagePricePerLiter, 124); // not (100+130)/2
    expect(s.fuelCostPerKm, 31);
  });

  test('monthly spend groups by month and respects the range', () {
    final s = FuelStatistics.compute([
      _fill('old', DateTime(2025, 12, 1), 900, 10, 900),
      _fill('a', DateTime(2026, 1, 5), 1000, 10, 1000),
      _fill('b', DateTime(2026, 1, 25), 1100, 10, 1100),
      _fill('c', DateTime(2026, 3, 2), 1300, 10, 1200),
    ], from: from, to: to);
    expect(s.monthly.map((m) => m.month.month), [1, 3]);
    expect(s.monthly.map((m) => m.cost), [2100, 1200]);
  });

  test('trend uses closing fill date; best/worst skip estimated periods', () {
    final s = FuelStatistics.compute([
      _fill('a', DateTime(2026, 1, 1), 1000, 40, 4000),
      _fill('b', DateTime(2026, 2, 1), 1400, 40, 4000), // 10 km/L
      _fill('c', DateTime(2026, 3, 1), 1600, 40, 4000), // 5 km/L
      _fill('d', DateTime(2026, 4, 1), 2200, 40, 4000), // 15 km/L
    ], from: from, to: to);
    expect(s.trend.map((p) => p.kmPerLiter), [10, 5, 15]);
    expect(s.best!.kmPerLiter, 15);
    expect(s.worst!.kmPerLiter, 5);
    expect(s.trend.every((p) => !p.isEstimated), isTrue);
  });

  test('single fill produces no trend points', () {
    final s = FuelStatistics.compute([
      _fill('a', DateTime(2026, 1, 1), 1000, 40, 4000),
    ], from: from, to: to);
    expect(s.trend, isEmpty);
    expect(s.best, isNull);
    expect(s.fillCount, 1);
  });
}
