// lib/features/fuel/domain/services/fuel_statistics.dart

import '../entities/fuel_entry.dart';
import 'fuel_consumption_calculator.dart';

class FuelMonthlySpend {
  const FuelMonthlySpend({
    required this.month,
    required this.cost,
    required this.liters,
  });
  final DateTime month;
  final double cost;
  final double liters;
}

/// Consumption of one measured period, placed on the date of its closing fill.
class FuelTrendPoint {
  const FuelTrendPoint({
    required this.date,
    required this.kmPerLiter,
    required this.isEstimated,
  });
  final DateTime date;
  final double kmPerLiter;
  final bool isEstimated;
}

class FuelStatistics {
  const FuelStatistics({
    required this.fillCount,
    required this.totalLiters,
    required this.totalCost,
    required this.distanceKm,
    required this.monthly,
    required this.trend,
    this.averagePricePerLiter,
    this.fuelCostPerKm,
    this.best,
    this.worst,
  });

  final int fillCount;
  final double totalLiters;
  final double totalCost;

  /// Distance driven across fills inside the range.
  final double distanceKm;

  /// Liter-weighted: total cost ÷ total liters (not a mean of unit prices).
  final double? averagePricePerLiter;
  final double? fuelCostPerKm;
  final List<FuelMonthlySpend> monthly;
  final List<FuelTrendPoint> trend;

  /// Best / worst *measured* periods; estimated periods are excluded.
  final FuelTrendPoint? best;
  final FuelTrendPoint? worst;

  bool get isEmpty => fillCount == 0;

  static FuelStatistics compute(
    Iterable<FuelEntry> entries, {
    required DateTime from,
    required DateTime to,
    double? tankCapacityLiters,
  }) {
    final all = FuelConsumptionCalculator.sortChronologically(entries);
    final byId = {for (final e in all) e.id: e};
    bool inRange(DateTime date) {
      final day = DateTime(date.year, date.month, date.day);
      return !day.isBefore(DateTime(from.year, from.month, from.day)) &&
          !day.isAfter(DateTime(to.year, to.month, to.day));
    }

    final inside = all.where((e) => inRange(e.date)).toList();
    final totalLiters = inside.fold<double>(0, (sum, e) => sum + e.liters);
    final totalCost = inside.fold<double>(0, (sum, e) => sum + e.totalCost);
    final distanceKm =
        inside.fold<double>(0, (sum, e) => sum + (e.distanceDriven ?? 0));

    final months = <DateTime, (double cost, double liters)>{};
    for (final e in inside) {
      final key = DateTime(e.date.year, e.date.month);
      final prev = months[key] ?? (0.0, 0.0);
      months[key] = (prev.$1 + e.totalCost, prev.$2 + e.liters);
    }
    final monthly = [
      for (final key in months.keys.toList()..sort())
        FuelMonthlySpend(
          month: key,
          cost: months[key]!.$1,
          liters: months[key]!.$2,
        ),
    ];

    final trend = <FuelTrendPoint>[];
    for (final segment in FuelConsumptionCalculator.segments(
      all,
      tankCapacityLiters: tankCapacityLiters,
    )) {
      final closing = byId[segment.endEntryId];
      if (closing == null || !inRange(closing.date)) continue;
      trend.add(FuelTrendPoint(
        date: closing.date,
        kmPerLiter: segment.kmPerLiter,
        isEstimated: segment.isEstimated,
      ));
    }
    final measured = trend.where((p) => !p.isEstimated).toList();
    FuelTrendPoint? best;
    FuelTrendPoint? worst;
    for (final p in measured) {
      if (best == null || p.kmPerLiter > best.kmPerLiter) best = p;
      if (worst == null || p.kmPerLiter < worst.kmPerLiter) worst = p;
    }

    return FuelStatistics(
      fillCount: inside.length,
      totalLiters: totalLiters,
      totalCost: totalCost,
      distanceKm: distanceKm,
      averagePricePerLiter: totalLiters > 0 ? totalCost / totalLiters : null,
      fuelCostPerKm: distanceKm > 0 ? totalCost / distanceKm : null,
      monthly: monthly,
      trend: trend,
      best: best,
      worst: worst,
    );
  }
}
