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
    required this.totalCost,
    required this.totalDistanceKm,
    required this.rentalBillable,
    required this.rentalDue,
    required this.rentalTripKm,
    required this.rentalTripCount,
    this.averageEfficiency,
    this.costPerKm,
  });
  final String vehicleId;
  final String vehicleName;
  final double fuelCost;
  final double maintenanceCost;
  final double totalCost;
  final double totalDistanceKm;
  /// Sum of billable trip amounts (after customer-paid fuel) in selected period.
  final double rentalBillable;
  final double rentalDue;
  final double rentalTripKm;
  final int rentalTripCount;
  final double? averageEfficiency;
  final double? costPerKm;
}

class MonthlyBreakdown {
  const MonthlyBreakdown({
    required this.month,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.rentalBillable,
  });
  final DateTime month;
  final double fuelCost;
  final double maintenanceCost;
  final double rentalBillable;
  double get totalSpend => fuelCost + maintenanceCost;
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
    required this.totalCost,
    required this.totalRentalBillable,
    required this.totalRentalDue,
    required this.monthlyBreakdown,
    required this.dateRange,
  });
  final String period;
  final List<VehicleAnalytics> vehicleAnalytics;
  final double totalFuelCost;
  final double totalMaintenanceCost;
  /// Operating spend (fuel + maintenance), excludes rental.
  final double totalCost;
  final double totalRentalBillable;
  final double totalRentalDue;
  final List<MonthlyBreakdown> monthlyBreakdown;
  final DateRange dateRange;
}

class AnalyticsError extends AnalyticsState {
  const AnalyticsError(this.message);
  final String message;
}
