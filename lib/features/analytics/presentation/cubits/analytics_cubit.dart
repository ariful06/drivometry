import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../fuel/domain/repositories/fuel_repository.dart';
import '../../../fuel/domain/services/fuel_consumption_calculator.dart';
import '../../../maintenance/domain/repositories/maintenance_repository.dart';
import '../../../parts/domain/entities/part_replacement.dart';
import '../../../parts/domain/repositories/part_replacement_repository.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';

part 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({
    required FuelRepository fuelRepository,
    required MaintenanceRepository maintenanceRepository,
    required VehicleRepository vehicleRepository,
    required ExpenseRepository expenseRepository,
    required PartReplacementRepository partRepository,
  })  : _fuelRepo = fuelRepository,
        _maintenanceRepo = maintenanceRepository,
        _vehicleRepo = vehicleRepository,
        _expenseRepo = expenseRepository,
        _partRepo = partRepository,
        super(const AnalyticsInitial());

  final FuelRepository _fuelRepo;
  final MaintenanceRepository _maintenanceRepo;
  final VehicleRepository _vehicleRepo;
  final ExpenseRepository _expenseRepo;
  final PartReplacementRepository _partRepo;

  Future<void> loadAnalytics(
      {required String period, String? vehicleId}) async {
    emit(const AnalyticsLoading());
    try {
      final now = DateTime.now();
      final range = _getDateRange(period, now);
      final vehicles = await _vehicleRepo.getAllVehicles();
      final allExpenses = await _expenseRepo.getAll();
      final allParts = <PartReplacement>[
        for (final vehicle in vehicles)
          ...await _partRepo.getByVehicle(vehicle.id),
      ];

      final vehicleAnalytics = <VehicleAnalytics>[];
      for (final vehicle in vehicles) {
        if (vehicleId != null && vehicle.id != vehicleId) continue;
        final fuelCost = await _fuelRepo.getTotalFuelCostByVehicleInRange(
            vehicle.id, range.from, range.to);
        final maintenanceCost =
            await _maintenanceRepo.getTotalMaintenanceCostByVehicleInRange(
                vehicle.id, range.from, range.to);
        final otherCost = allExpenses
            .where((e) => e.vehicleId == vehicle.id && _inRange(e.date, range))
            .fold<double>(0, (sum, e) => sum + e.amount);
        final partsCost = allParts
            .where((p) =>
                p.vehicleId == vehicle.id &&
                p.installedAt != null &&
                _inRange(p.installedAt!, range))
            .fold<double>(0, (sum, p) => sum + (p.cost ?? 0));
        final totalCost = fuelCost + maintenanceCost + partsCost + otherCost;
        final fuelEntries = await _fuelRepo.getFuelEntriesByVehicle(vehicle.id);
        final entriesInRange =
            fuelEntries.where((entry) => _inRange(entry.date, range)).toList();
        final totalDistance = entriesInRange.fold<double>(
          0,
          (runningKm, fuelEntryRow) =>
              runningKm + (fuelEntryRow.distanceDriven ?? 0),
        );
        final dateById = {for (final e in fuelEntries) e.id: e.date};
        var segmentKm = 0.0;
        var segmentLiters = 0.0;
        for (final segment in FuelConsumptionCalculator.segments(
          fuelEntries,
          tankCapacityLiters: vehicle.tankCapacityLiters,
        )) {
          final closedOn = dateById[segment.endEntryId];
          if (closedOn == null || !_inRange(closedOn, range)) continue;
          segmentKm += segment.distanceKm;
          segmentLiters += segment.liters;
        }
        final avgEfficiency =
            segmentLiters > 0 ? segmentKm / segmentLiters : null;

        vehicleAnalytics.add(VehicleAnalytics(
          vehicleId: vehicle.id,
          vehicleName: vehicle.name,
          fuelCost: fuelCost,
          maintenanceCost: maintenanceCost,
          partsCost: partsCost,
          otherCost: otherCost,
          totalCost: totalCost,
          totalDistanceKm: totalDistance,
          averageEfficiency: avgEfficiency,
          costPerKm: totalDistance > 0 ? totalCost / totalDistance : null,
        ));
      }

      final monthlyData =
          await _buildMonthlyBreakdown(vehicleId, now, allExpenses, allParts);
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
      final totalParts = vehicleAnalytics.fold<double>(
        0,
        (sum, vehicleMetricRow) => sum + vehicleMetricRow.partsCost,
      );
      final totalOther = vehicleAnalytics.fold<double>(
        0,
        (sum, vehicleMetricRow) => sum + vehicleMetricRow.otherCost,
      );

      emit(AnalyticsLoaded(
        period: period,
        vehicleAnalytics: vehicleAnalytics,
        totalFuelCost: totalFuel,
        totalMaintenanceCost: totalMaintenance,
        totalPartsCost: totalParts,
        totalOtherCost: totalOther,
        totalCost: totalFuel + totalMaintenance + totalParts + totalOther,
        monthlyBreakdown: monthlyData,
        dateRange: range,
      ));
    } catch (error) {
      emit(AnalyticsError(error.toString()));
    }
  }

  bool _inRange(DateTime date, DateRange range) {
    final day = DateTime(date.year, date.month, date.day);
    final from = DateTime(range.from.year, range.from.month, range.from.day);
    final to = DateTime(range.to.year, range.to.month, range.to.day);
    return !day.isBefore(from) && !day.isAfter(to);
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
    List<Expense> allExpenses,
    List<PartReplacement> allParts,
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
      final monthRange = DateRange(from: month, to: monthEnd);
      final otherCost = allExpenses
          .where((e) => vehicleId == null || e.vehicleId == vehicleId)
          .where((e) => _inRange(e.date, monthRange))
          .fold<double>(0, (sum, e) => sum + e.amount);
      final partsCost = allParts
          .where((p) => vehicleId == null || p.vehicleId == vehicleId)
          .where((p) =>
              p.installedAt != null && _inRange(p.installedAt!, monthRange))
          .fold<double>(0, (sum, p) => sum + (p.cost ?? 0));
      result.add(MonthlyBreakdown(
        month: month,
        fuelCost: fuelCost,
        maintenanceCost: maintenanceCost,
        partsCost: partsCost,
        otherCost: otherCost,
      ));
    }
    return result;
  }
}
