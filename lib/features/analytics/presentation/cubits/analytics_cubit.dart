import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../fuel/domain/repositories/fuel_repository.dart';
import '../../../maintenance/domain/repositories/maintenance_repository.dart';
import '../../../rentals/domain/entities/rental_entry.dart';
import '../../../rentals/domain/repositories/rental_repository.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';

part 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({
    required FuelRepository fuelRepository,
    required MaintenanceRepository maintenanceRepository,
    required VehicleRepository vehicleRepository,
    required RentalRepository rentalRepository,
  })  : _fuelRepo = fuelRepository,
        _maintenanceRepo = maintenanceRepository,
        _vehicleRepo = vehicleRepository,
        _rentalRepo = rentalRepository,
        super(const AnalyticsInitial());

  final FuelRepository _fuelRepo;
  final MaintenanceRepository _maintenanceRepo;
  final VehicleRepository _vehicleRepo;
  final RentalRepository _rentalRepo;

  Future<void> loadAnalytics({required String period, String? vehicleId}) async {
    emit(const AnalyticsLoading());
    try {
      final now = DateTime.now();
      final range = _getDateRange(period, now);
      final vehicles = await _vehicleRepo.getAllVehicles();
      final allRentals = await _rentalRepo.getAllRentals();

      final vehicleAnalytics = <VehicleAnalytics>[];
      for (final v in vehicles) {
        if (vehicleId != null && v.id != vehicleId) continue;
        final fuelCost = await _fuelRepo.getTotalFuelCostByVehicleInRange(v.id, range.from, range.to);
        final maintenanceCost =
            await _maintenanceRepo.getTotalMaintenanceCostByVehicleInRange(v.id, range.from, range.to);
        final fuelEntries = await _fuelRepo.getFuelEntriesByVehicle(v.id);
        final totalDistance = fuelEntries.fold<double>(0, (s, e) => s + (e.distanceDriven ?? 0));
        final efficiencies = fuelEntries.where((e) => e.fuelEfficiency != null).toList();
        final avgEfficiency = efficiencies.isEmpty
            ? null
            : efficiencies.fold<double>(0, (s, e) => s + e.fuelEfficiency!) / efficiencies.length;

        final rentalList =
            allRentals.where((r) => r.vehicleId == v.id).where((r) => _inRange(r.bookingDate, range)).toList();
        final rentalBillable = rentalList.fold<double>(
          0,
          (s, r) =>
              s +
              RentalEntry.billableTripAmount(
                rentFareAmount: r.rentFareAmount,
                fuelCost: r.fuelCost,
                customerPaidFuelBill: r.customerPaidFuelBill,
              ),
        );
        final rentalDue = rentalList.fold<double>(0, (s, r) => s + r.dueAmount);
        final rentalTripKm = rentalList.fold<double>(0, (s, r) => s + r.totalKm);

        vehicleAnalytics.add(VehicleAnalytics(
          vehicleId: v.id,
          vehicleName: v.name,
          fuelCost: fuelCost,
          maintenanceCost: maintenanceCost,
          totalCost: fuelCost + maintenanceCost,
          totalDistanceKm: totalDistance,
          rentalBillable: rentalBillable,
          rentalDue: rentalDue,
          rentalTripKm: rentalTripKm,
          rentalTripCount: rentalList.length,
          averageEfficiency: avgEfficiency,
          costPerKm: totalDistance > 0 ? (fuelCost + maintenanceCost) / totalDistance : null,
        ));
      }

      final monthlyData = await _buildMonthlyBreakdown(vehicleId, now, allRentals);
      final totalFuel = vehicleAnalytics.fold<double>(0, (s, v) => s + v.fuelCost);
      final totalMaintenance = vehicleAnalytics.fold<double>(0, (s, v) => s + v.maintenanceCost);
      final totalRentalBillable = vehicleAnalytics.fold<double>(0, (s, v) => s + v.rentalBillable);
      final totalRentalDue = vehicleAnalytics.fold<double>(0, (s, v) => s + v.rentalDue);

      emit(AnalyticsLoaded(
        period: period,
        vehicleAnalytics: vehicleAnalytics,
        totalFuelCost: totalFuel,
        totalMaintenanceCost: totalMaintenance,
        totalCost: totalFuel + totalMaintenance,
        totalRentalBillable: totalRentalBillable,
        totalRentalDue: totalRentalDue,
        monthlyBreakdown: monthlyData,
        dateRange: range,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  bool _inRange(DateTime bookingDate, DateRange range) {
    final day = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
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
    List<RentalEntry> allRentals,
  ) async {
    final result = <MonthlyBreakdown>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final double fuelCost;
      final double maintenanceCost;
      if (vehicleId != null) {
        fuelCost = await _fuelRepo.getTotalFuelCostByVehicleInRange(vehicleId, month, monthEnd);
        maintenanceCost =
            await _maintenanceRepo.getTotalMaintenanceCostByVehicleInRange(vehicleId, month, monthEnd);
      } else {
        fuelCost = await _fuelRepo.getTotalFuelCostInRange(month, monthEnd);
        maintenanceCost = await _maintenanceRepo.getTotalMaintenanceCostInRange(month, monthEnd);
      }
      final range = DateRange(from: month, to: monthEnd);
      final rentalBillable = allRentals
          .where((r) => vehicleId == null || r.vehicleId == vehicleId)
          .where((r) => _inRange(r.bookingDate, range))
          .fold<double>(
            0,
            (s, r) =>
                s +
                RentalEntry.billableTripAmount(
                  rentFareAmount: r.rentFareAmount,
                  fuelCost: r.fuelCost,
                  customerPaidFuelBill: r.customerPaidFuelBill,
                ),
          );
      result.add(MonthlyBreakdown(
        month: month,
        fuelCost: fuelCost,
        maintenanceCost: maintenanceCost,
        rentalBillable: rentalBillable,
      ));
    }
    return result;
  }
}
