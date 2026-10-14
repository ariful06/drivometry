// lib/features/maintenance/domain/usecases/maintenance_usecases.dart

import '../../../notifications/domain/notification_service.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';
import '../entities/maintenance_entry.dart';
import '../maintenance_notification_ids.dart';
import '../repositories/maintenance_repository.dart';

class GetMaintenanceByVehicle {
  const GetMaintenanceByVehicle(this._repository);
  final MaintenanceRepository _repository;

  Future<List<MaintenanceEntry>> call(String vehicleId) =>
      _repository.getMaintenanceByVehicle(vehicleId);
}

class GetUpcomingMaintenance {
  const GetUpcomingMaintenance(this._repository);
  final MaintenanceRepository _repository;

  Future<List<MaintenanceEntry>> call({int daysAhead = 7}) =>
      _repository.getUpcomingMaintenance(daysAhead: daysAhead);
}

class AddMaintenance {
  const AddMaintenance(this._repository);
  final MaintenanceRepository _repository;

  Future<void> call(MaintenanceEntry entry) =>
      _repository.addMaintenance(entry);
}

class UpdateMaintenance {
  const UpdateMaintenance(this._repository);
  final MaintenanceRepository _repository;

  Future<void> call(MaintenanceEntry entry) =>
      _repository.updateMaintenance(entry);
}

class DeleteMaintenance {
  const DeleteMaintenance(this._repository);
  final MaintenanceRepository _repository;

  Future<void> call(String id) => _repository.deleteMaintenance(id);
}

class WatchMaintenanceByVehicle {
  const WatchMaintenanceByVehicle(this._repository);
  final MaintenanceRepository _repository;

  Stream<List<MaintenanceEntry>> call(String vehicleId) =>
      _repository.watchMaintenanceByVehicle(vehicleId);
}

/// Schedules OS notifications when maintenance is due by odometer (≤50 km left
/// or overdue) or by calendar (within 7 days or overdue). Each case fires once
/// per entry (until cleared via reminder-done or data changes).
class RunMaintenanceReminderChecks {
  RunMaintenanceReminderChecks(
    this._vehicleRepository,
    this._maintenanceRepository,
    this._notificationService,
  );

  final VehicleRepository _vehicleRepository;
  final MaintenanceRepository _maintenanceRepository;
  final NotificationService _notificationService;

  static const int proximityKm = 50;
  static const int proximityDays = 7;

  Future<void> call() async {
    try {
      final vehicles = await _vehicleRepository.getVehicles();
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      for (final vehicle in vehicles) {
        final entries =
            await _maintenanceRepository.getMaintenanceByVehicle(vehicle.id);
        for (final entry in entries) {
          if (entry.reminderAcknowledged) continue;

          var working = entry;
          var changed = false;

          if (!working.odometerReminderScheduled &&
              working.nextServiceOdometer != null) {
            final remKm =
                working.nextServiceOdometer! - vehicle.currentOdometer.ceil();
            if (remKm <= proximityKm) {
              final baseId =
                  MaintenanceNotificationIds.odometerBurstBase(working.id);
              await _notificationService.scheduleOdometerDueReminders(
                baseId: baseId,
                title: 'Service coming up: ${working.title}',
                body: remKm <= 0
                    ? '${vehicle.name}: due at ${working.nextServiceOdometer} km — odometer has passed.'
                    : '${vehicle.name}: about $remKm km until ${working.nextServiceOdometer} km (${working.title}).',
              );
              working = working.copyWith(
                notificationId: baseId,
                odometerReminderScheduled: true,
              );
              changed = true;
            }
          }

          if (!working.dateProximityReminderScheduled &&
              working.nextServiceDate != null) {
            final upcomingServiceDateTime = working.nextServiceDate!;
            final upcomingDueCalendarDay = DateTime(
              upcomingServiceDateTime.year,
              upcomingServiceDateTime.month,
              upcomingServiceDateTime.day,
            );
            final daysUntilDue =
                upcomingDueCalendarDay.difference(startOfToday).inDays;
            if (daysUntilDue <= proximityDays) {
              final baseId =
                  MaintenanceNotificationIds.dateBurstBase(working.id);
              late String body;
              if (daysUntilDue < 0) {
                body =
                    '${vehicle.name}: "${working.title}" was due ${-daysUntilDue} day${-daysUntilDue == 1 ? '' : 's'} ago.';
              } else if (daysUntilDue == 0) {
                body = '${vehicle.name}: "${working.title}" is due today.';
              } else {
                body =
                    '${vehicle.name}: "${working.title}" in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}.';
              }
              await _notificationService.scheduleOdometerDueReminders(
                baseId: baseId,
                title: 'Maintenance reminder: ${working.title}',
                body: body,
              );
              working = working.copyWith(dateProximityReminderScheduled: true);
              changed = true;
            }
          }

          if (changed) await _maintenanceRepository.updateMaintenance(working);
        }
      }
    } catch (_) {}
  }
}
