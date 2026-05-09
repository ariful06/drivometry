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

  /// Lines / labels from [description] and [title], lowercased for matching.
  static Set<String> _descriptorTokens(MaintenanceEntry maintenanceEntry) {
    final rawDescription = maintenanceEntry.description.trim();
    if (rawDescription.isEmpty) {
      final titleLower = maintenanceEntry.title.trim().toLowerCase();
      return titleLower.isEmpty ? <String>{} : {titleLower};
    }
    return rawDescription
        .split(RegExp(r'[\n,;]'))
        .map((fragment) => fragment.trim().toLowerCase())
        .where((fragment) => fragment.isNotEmpty)
        .toSet();
  }

  /// True when [newer] is a later log for the same maintenance line as [older]
  /// (e.g. replaced oil change vs previous oil change record).
  static bool _sameMaintenanceLine(MaintenanceEntry older, MaintenanceEntry newer) {
    if (older.type != newer.type) return false;
    if (older.type == 'repair') {
      final olderTitleLower = older.title.trim().toLowerCase();
      final newerTitleLower = newer.title.trim().toLowerCase();
      if (olderTitleLower.isNotEmpty &&
          newerTitleLower.isNotEmpty &&
          olderTitleLower != newerTitleLower) {
        return false;
      }
      final olderTokens = _descriptorTokens(older);
      final newerTokens = _descriptorTokens(newer);
      if (olderTokens.isEmpty && newerTokens.isEmpty) {
        return olderTitleLower == newerTitleLower;
      }
      for (final token in olderTokens) {
        if (newerTokens.contains(token)) return true;
      }
      return false;
    }
    final olderTokens = _descriptorTokens(older);
    final newerTokens = _descriptorTokens(newer);
    if (olderTokens.isEmpty || newerTokens.isEmpty) {
      final olderTitleLower = older.title.trim().toLowerCase();
      final newerTitleLower = newer.title.trim().toLowerCase();
      return olderTitleLower.isNotEmpty && olderTitleLower == newerTitleLower;
    }
    for (final token in olderTokens) {
      if (newerTokens.contains(token)) return true;
    }
    return false;
  }

  static bool _isSuperseded(
    MaintenanceEntry candidateEntry,
    List<MaintenanceEntry> allEntries,
  ) {
    for (final otherEntry in allEntries) {
      if (otherEntry.id == candidateEntry.id) continue;
      if (!otherEntry.serviceDate.isAfter(candidateEntry.serviceDate)) continue;
      if (_sameMaintenanceLine(candidateEntry, otherEntry)) return true;
    }
    return false;
  }

  /// Entries that should drive dashboard service alerts: has a next target,
  /// not dismissed in Reminders, and not replaced by a newer same-line log.
  static List<MaintenanceEntry> entriesForSchedulingAlerts(
    List<MaintenanceEntry> maintenanceEntries,
  ) {
    return maintenanceEntries.where((entry) {
      if (entry.reminderAcknowledged) return false;
      if (entry.nextServiceDate == null && entry.nextServiceOdometer == null) {
        return false;
      }
      if (_isSuperseded(entry, maintenanceEntries)) return false;
      return true;
    }).toList();
  }

  static MaintenanceEntry? _pickClosestUpcoming(
    List<MaintenanceEntry> entries,
    Vehicle vehicle,
  ) {
    MaintenanceEntry? entryWithClosestDate;
    DateTime? closestNextServiceCalendarDay;
    for (final entry in entries) {
      final nextServiceDateTime = entry.nextServiceDate;
      if (nextServiceDateTime == null) continue;
      final calendarDay = DateTime(
        nextServiceDateTime.year,
        nextServiceDateTime.month,
        nextServiceDateTime.day,
      );
      if (closestNextServiceCalendarDay == null ||
          calendarDay.isBefore(closestNextServiceCalendarDay)) {
        closestNextServiceCalendarDay = calendarDay;
        entryWithClosestDate = entry;
      }
    }
    if (entryWithClosestDate != null) return entryWithClosestDate;

    final currentKm = vehicle.currentOdometer.ceil();
    MaintenanceEntry? entryWithClosestOdometerDue;
    int? smallestKmRemainingUntilDue;
    for (final entry in entries) {
      final thresholdKm = entry.nextServiceOdometer;
      if (thresholdKm == null) continue;
      final kmRemaining = thresholdKm - currentKm;
      if (smallestKmRemainingUntilDue == null ||
          kmRemaining < smallestKmRemainingUntilDue) {
        smallestKmRemainingUntilDue = kmRemaining;
        entryWithClosestOdometerDue = entry;
      }
    }
    return entryWithClosestOdometerDue;
  }

  static String? _formatClosest(MaintenanceEntry? entry) {
    if (entry == null) return null;
    final parts = <String>[entry.title];
    if (entry.nextServiceDate != null) {
      final nextDate = entry.nextServiceDate!;
      parts.add('${nextDate.day}/${nextDate.month}/${nextDate.year}');
    } else if (entry.nextServiceOdometer != null) {
      parts.add('@ ${entry.nextServiceOdometer} km');
    }
    return parts.join(' · ');
  }

  static String? _closestServiceRemaining(MaintenanceEntry? entry, Vehicle vehicle) {
    if (entry == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (entry.nextServiceDate != null) {
      final nextDate = entry.nextServiceDate!;
      final nextDueCalendarDay = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
      );
      final diff = nextDueCalendarDay.difference(today).inDays;
      if (diff < 0) {
        return 'Overdue by ${-diff} day${(-diff) == 1 ? '' : 's'}';
      }
      if (diff == 0) return 'Due today';
      return '$diff day${diff == 1 ? '' : 's'} remaining';
    }
    if (entry.nextServiceOdometer != null) {
      final rem =
          entry.nextServiceOdometer! - vehicle.currentOdometer.ceil();
      if (rem < 0) {
        return 'Overdue by ${-rem} km';
      }
      if (rem == 0) return 'Due now';
      return '$rem km remaining';
    }
    return null;
  }

  static bool _isServiceUrgent(MaintenanceEntry entry, Vehicle vehicle) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextServiceCalendarDate = entry.nextServiceDate;
    if (nextServiceCalendarDate != null) {
      final diff =
          DateTime(nextServiceCalendarDate.year, nextServiceCalendarDate.month,
                  nextServiceCalendarDate.day,)
              .difference(today)
              .inDays;
      if (diff <= serviceSoonDays) return true;
    }
    final nextDueOdometerKm = entry.nextServiceOdometer;
    if (nextDueOdometerKm != null) {
      final rem = nextDueOdometerKm - vehicle.currentOdometer.ceil();
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
    final scheduleEntries = entriesForSchedulingAlerts(entries);
    final closest = _pickClosestUpcoming(scheduleEntries, vehicle);
    final closestServiceSummary = _formatClosest(closest);
    final closestServiceRemaining = _closestServiceRemaining(closest, vehicle);
    final urgentEntries =
        scheduleEntries.where((entry) => _isServiceUrgent(entry, vehicle)).toList();
    final serviceAttentionCount = urgentEntries.length;
    final urgentTitles = urgentEntries.map((entry) {
      final type = entry.type.trim();
      final title = entry.title.trim();
      final description = entry.description.trim();
      final itemName = description.isNotEmpty ? description : title;
      if (type.isNotEmpty && itemName.isNotEmpty) return '$type: $itemName';
      if (itemName.isNotEmpty) return itemName;
      return type;
    }).where((trimmedTitle) => trimmedTitle.isNotEmpty).toSet().toList();
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
    for (final replacementRecord in parts) {
      final remaining = partsLifecycle.remainingLifeKm(
        replacementRecord,
        vehicle.currentOdometer,
      );
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
    for (final rental in rentals) {
      rentalIncome += RentalEntry.billableTripAmount(
        rentFareAmount: rental.rentFareAmount,
        fuelCost: rental.fuelCost,
        customerPaidFuelBill: rental.customerPaidFuelBill,
      );
      if (rental.paymentStatus == 'Paid') {
        paid++;
      } else if (rental.paymentStatus == 'Partial') {
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
