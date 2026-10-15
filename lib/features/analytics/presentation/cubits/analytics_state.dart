part of 'analytics_cubit.dart';

class DateRange {
  const DateRange({required this.from, required this.to});
  final DateTime from;
  final DateTime to;
}

class VehicleAnalytics {
  const VehicleAnalytics({
    required this.vehicleId,
    required this.vehicleName,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.otherCost,
    required this.totalCost,
    required this.totalDistanceKm,
    this.averageEfficiency,
    this.costPerKm,
  });
  final String vehicleId;
  final String vehicleName;
  final double fuelCost;
  final double maintenanceCost;

  /// General expenses (insurance, tax, parking, ...).
  final double otherCost;
  final double totalCost;
  final double totalDistanceKm;
  final double? averageEfficiency;
  final double? costPerKm;
}

class MonthlyBreakdown {
  const MonthlyBreakdown({
    required this.month,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.otherCost,
  });
  final DateTime month;
  final double fuelCost;
  final double maintenanceCost;
  final double otherCost;
  double get totalSpend => fuelCost + maintenanceCost + otherCost;
}

sealed class AnalyticsState {
  const AnalyticsState();
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsLoaded extends AnalyticsState {
  const AnalyticsLoaded({
    required this.period,
    required this.vehicleAnalytics,
    required this.totalFuelCost,
    required this.totalMaintenanceCost,
    required this.totalOtherCost,
    required this.totalCost,
    required this.monthlyBreakdown,
    required this.dateRange,
  });
  final String period;
  final List<VehicleAnalytics> vehicleAnalytics;
  final double totalFuelCost;
  final double totalMaintenanceCost;
  final double totalOtherCost;

  /// Total cost (fuel + maintenance + other expenses).
  final double totalCost;
  final List<MonthlyBreakdown> monthlyBreakdown;
  final DateRange dateRange;
}

class AnalyticsError extends AnalyticsState {
  const AnalyticsError(this.message);
  final String message;
}
