import 'package:flutter/foundation.dart';

import '../../../../injection_container.dart';
import '../../../fuel/domain/usecases/fuel_usecases.dart';
import '../../../maintenance/domain/entities/maintenance_entry.dart';
import '../../../maintenance/domain/repositories/maintenance_repository.dart';
import '../../../maintenance/domain/usecases/maintenance_usecases.dart';
import '../../../parts/domain/repositories/part_replacement_repository.dart';
import '../../../parts/domain/services/parts_lifecycle_service.dart';
import '../../../rentals/domain/entities/rental_entry.dart';
import '../../../rentals/domain/usecases/rental_usecases.dart';
import '../../domain/entities/vehicle.dart';

/// Per-vehicle figures for the vehicles dashboard list.
@immutable
class VehicleDashboardMetrics {
  const VehicleDashboardMetrics({
    required this.fuelCost,
    required this.maintenanceCost,
    required this.rentalIncome,
    required this.totalOperatingCost,
    required this.partWarningsCount,
    required this.closestServiceSummary,
    required this.closestServiceRemaining,
    required this.serviceAttentionCount,
    required this.serviceAttentionItemsLabel,
    required this.hasUrgentServiceAttention,
    required this.paidRentalCount,
    required this.partialRentalCount,
  });

  final double fuelCost;
  final double maintenanceCost;
  /// Sum of billable trip amounts for this vehicle (lifetime).
  final double rentalIncome;
  /// Fuel + maintenance only (not net of rental income).
  final double totalOperatingCost;
  final int partWarningsCount;
  /// Short line for the nearest upcoming service (date or odometer).
  final String? closestServiceSummary;
  /// Human-readable remaining/overdue for nearest service trigger.
  final String? closestServiceRemaining;
  /// Number of services that are overdue or close soon.
  final int serviceAttentionCount;
  /// Comma-separated service titles that need attention.
  final String? serviceAttentionItemsLabel;
  /// True when at least one service is overdue or close soon.
  final bool hasUrgentServiceAttention;
  final int paidRentalCount;
  final int partialRentalCount;

  static const double partWarningThresholdKm = 500;
  static const int serviceSoonDays = 7;
  static const int serviceSoonKm = 500;

  static MaintenanceEntry? _pickClosestUpcoming(
    List<MaintenanceEntry> entries,
    Vehicle vehicle,
  ) {
    MaintenanceEntry? bestDate;
    DateTime? bestDateValue;
    for (final e in entries) {
      final d = e.nextServiceDate;
      if (d == null) continue;
      final dOnly = DateTime(d.year, d.month, d.day);
      if (bestDateValue == null || dOnly.isBefore(bestDateValue)) {
        bestDateValue = dOnly;
        bestDate = e;
      }
    }
    if (bestDate != null) return bestDate;

    final cur = vehicle.currentOdometer.ceil();
    MaintenanceEntry? bestOdo;
    int? bestRemaining;
    for (final e in entries) {
      final o = e.nextServiceOdometer;
      if (o == null) continue;
      final rem = o - cur;
      if (bestRemaining == null || rem < bestRemaining) {
        bestRemaining = rem;
        bestOdo = e;
      }
    }
    return bestOdo;
  }

  static String? _formatClosest(MaintenanceEntry? e) {
    if (e == null) return null;
    final parts = <String>[e.title];
    if (e.nextServiceDate != null) {
      final d = e.nextServiceDate!;
      parts.add('${d.day}/${d.month}/${d.year}');
    } else if (e.nextServiceOdometer != null) {
      parts.add('@ ${e.nextServiceOdometer} km');
    }
    return parts.join(' · ');
  }

  static String? _closestServiceRemaining(MaintenanceEntry? e, Vehicle vehicle) {
    if (e == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (e.nextServiceDate != null) {
      final d = e.nextServiceDate!;
      final dOnly = DateTime(d.year, d.month, d.day);
      final diff = dOnly.difference(today).inDays;
      if (diff < 0) {
        return 'Overdue by ${-diff} day${(-diff) == 1 ? '' : 's'}';
      }
      if (diff == 0) return 'Due today';
      return '$diff day${diff == 1 ? '' : 's'} remaining';
    }
    if (e.nextServiceOdometer != null) {
      final rem = e.nextServiceOdometer! - vehicle.currentOdometer.ceil();
      if (rem < 0) {
        return 'Overdue by ${-rem} km';
      }
      if (rem == 0) return 'Due now';
      return '$rem km remaining';
    }
    return null;
  }

  static bool _isServiceUrgent(MaintenanceEntry e, Vehicle vehicle) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = e.nextServiceDate;
    if (d != null) {
      final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
      if (diff <= serviceSoonDays) return true;
    }
    final o = e.nextServiceOdometer;
    if (o != null) {
      final rem = o - vehicle.currentOdometer.ceil();
      if (rem <= serviceSoonKm) return true;
    }
    return false;
  }

  static Future<VehicleDashboardMetrics> load(Vehicle vehicle) async {
    final getMaintenance = sl<GetMaintenanceByVehicle>();
    final maintenanceRepo = sl<MaintenanceRepository>();
    final partRepo = sl<PartReplacementRepository>();
    final partsLifecycle = sl<PartsLifecycleService>();
    final getFuelCost = sl<GetTotalFuelCostByVehicle>();
    final getRentals = sl<GetRentalsByVehicle>();

    final entries = await getMaintenance(vehicle.id);
    final closest = _pickClosestUpcoming(entries, vehicle);
    final closestServiceSummary = _formatClosest(closest);
    final closestServiceRemaining = _closestServiceRemaining(closest, vehicle);
    final urgentEntries = entries.where((e) => _isServiceUrgent(e, vehicle)).toList();
    final serviceAttentionCount = urgentEntries.length;
    final urgentTitles = urgentEntries.map((e) {
      final type = e.type.trim();
      final title = e.title.trim();
      final description = e.description.trim();
      final itemName = description.isNotEmpty ? description : title;
      if (type.isNotEmpty && itemName.isNotEmpty) return '$type: $itemName';
      if (itemName.isNotEmpty) return itemName;
      return type;
    }).where((t) => t.isNotEmpty).toSet().toList();
    String? serviceAttentionItemsLabel;
    if (urgentTitles.isNotEmpty) {
      final preview = urgentTitles.take(3).join(', ');
      if (urgentTitles.length > 3) {
        serviceAttentionItemsLabel = '$preview +${urgentTitles.length - 3} more';
      } else {
        serviceAttentionItemsLabel = preview;
      }
    }

    var partWarnings = 0;
    final parts = await partRepo.getByVehicle(vehicle.id);
    for (final p in parts) {
      final remaining = partsLifecycle.remainingLifeKm(p, vehicle.currentOdometer);
      if (remaining < partWarningThresholdKm && remaining >= 0) {
        partWarnings++;
      }
    }

    final maintCost = await maintenanceRepo.getTotalMaintenanceCostByVehicle(vehicle.id);
    final fuelCost = await getFuelCost(vehicle.id);

    final rentals = await getRentals(vehicle.id);
    var rentalIncome = 0.0;
    var paid = 0;
    var partial = 0;
    for (final r in rentals) {
      rentalIncome += RentalEntry.billableTripAmount(
        rentFareAmount: r.rentFareAmount,
        fuelCost: r.fuelCost,
        customerPaidFuelBill: r.customerPaidFuelBill,
      );
      if (r.paymentStatus == 'Paid') {
        paid++;
      } else if (r.paymentStatus == 'Partial') {
        partial++;
      }
    }

    return VehicleDashboardMetrics(
      fuelCost: fuelCost,
      maintenanceCost: maintCost,
      rentalIncome: rentalIncome,
      totalOperatingCost: fuelCost + maintCost,
      partWarningsCount: partWarnings,
      closestServiceSummary: closestServiceSummary,
      closestServiceRemaining: closestServiceRemaining,
      serviceAttentionCount: serviceAttentionCount,
      serviceAttentionItemsLabel: serviceAttentionItemsLabel,
      hasUrgentServiceAttention: serviceAttentionCount > 0,
      paidRentalCount: paid,
      partialRentalCount: partial,
    );
  }

  static Future<List<VehicleDashboardMetrics>> loadAll(List<Vehicle> vehicles) =>
      Future.wait(vehicles.map(load));
}
