import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../fuel/domain/repositories/fuel_repository.dart';
import '../../../fuel/domain/services/fuel_consumption_calculator.dart';
import '../../../maintenance/domain/repositories/maintenance_repository.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';

part 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({
    required FuelRepository fuelRepository,
    required MaintenanceRepository maintenanceRepository,
    required VehicleRepository vehicleRepository,
  })  : _fuelRepo = fuelRepository,
        _maintenanceRepo = maintenanceRepository,
        _vehicleRepo = vehicleRepository,
        super(const AnalyticsInitial());

  final FuelRepository _fuelRepo;
  final MaintenanceRepository _maintenanceRepo;
  final VehicleRepository _vehicleRepo;

  Future<void> loadAnalytics(
      {required String period, String? vehicleId}) async {
    emit(const AnalyticsLoading());
    try {
      final now = DateTime.now();
      final range = _getDateRange(period, now);
      final vehicles = await _vehicleRepo.getAllVehicles();

      final vehicleAnalytics = <VehicleAnalytics>[];
      for (final vehicle in vehicles) {
        if (vehicleId != null && vehicle.id != vehicleId) continue;
        final fuelCost = await _fuelRepo.getTotalFuelCostByVehicleInRange(
            vehicle.id, range.from, range.to);
        final maintenanceCost =
            await _maintenanceRepo.getTotalMaintenanceCostByVehicleInRange(
                vehicle.id, range.from, range.to);
        final fuelEntries = await _fuelRepo.getFuelEntriesByVehicle(vehicle.id);
        final totalDistance = fuelEntries.fold<double>(
          0,
          (runningKm, fuelEntryRow) =>
              runningKm + (fuelEntryRow.distanceDriven ?? 0),
        );
        final avgEfficiency = FuelConsumptionCalculator.averageKmPerLiter(
          fuelEntries,
          tankCapacityLiters: vehicle.tankCapacityLiters,
        );

        vehicleAnalytics.add(VehicleAnalytics(
          vehicleId: vehicle.id,
          vehicleName: vehicle.name,
          fuelCost: fuelCost,
          maintenanceCost: maintenanceCost,
          totalCost: fuelCost + maintenanceCost,
          totalDistanceKm: totalDistance,
          averageEfficiency: avgEfficiency,
          costPerKm: totalDistance > 0
              ? (fuelCost + maintenanceCost) / totalDistance
              : null,
        ));
      }

      final monthlyData = await _buildMonthlyBreakdown(vehicleId, now);
      final totalFuel = vehicleAnalytics.fold<double>(
        0,
        (runningFuelSum, vehicleMetricRow) =>
            runningFuelSum + vehicleMetricRow.fuelCost,
      );
      final totalMaintenance = vehicleAnalytics.fold<double>(
        0,
        (runningMaintenanceSum, vehicleMetricRow) =>
            runningMaintenanceSum + vehicleMetricRow.maintenanceCost,
      );

      emit(AnalyticsLoaded(
        period: period,
        vehicleAnalytics: vehicleAnalytics,
        totalFuelCost: totalFuel,
        totalMaintenanceCost: totalMaintenance,
        totalCost: totalFuel + totalMaintenance,
        monthlyBreakdown: monthlyData,
        dateRange: range,
      ));
    } catch (error) {
      emit(AnalyticsError(error.toString()));
    }
  }

  DateRange _getDateRange(String period, DateTime now) {
    switch (period) {
      case 'Weekly':
        return DateRange(from: now.subtract(const Duration(days: 7)), to: now);
      case 'Monthly':
        return DateRange(from: DateTime(now.year, now.month, 1), to: now);
      case 'Yearly':
        return DateRange(from: DateTime(now.year, 1, 1), to: now);
      default:
        return DateRange(from: DateTime(2000), to: now);
    }
  }

  Future<List<MonthlyBreakdown>> _buildMonthlyBreakdown(
    String? vehicleId,
    DateTime now,
  ) async {
    final result = <MonthlyBreakdown>[];
    for (var monthsBackIndex = 5; monthsBackIndex >= 0; monthsBackIndex--) {
      final month = DateTime(now.year, now.month - monthsBackIndex, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final double fuelCost;
      final double maintenanceCost;
      if (vehicleId != null) {
        fuelCost = await _fuelRepo.getTotalFuelCostByVehicleInRange(
            vehicleId, month, monthEnd);
        maintenanceCost =
            await _maintenanceRepo.getTotalMaintenanceCostByVehicleInRange(
                vehicleId, month, monthEnd);
      } else {
        fuelCost = await _fuelRepo.getTotalFuelCostInRange(month, monthEnd);
        maintenanceCost = await _maintenanceRepo.getTotalMaintenanceCostInRange(
            month, monthEnd);
      }
      result.add(MonthlyBreakdown(
        month: month,
        fuelCost: fuelCost,
        maintenanceCost: maintenanceCost,
      ));
    }
    return result;
  }
}
