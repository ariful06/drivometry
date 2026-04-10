// lib/features/maintenance/domain/usecases/maintenance_usecases.dart

import '../../../notifications/domain/notification_service.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';
import '../entities/maintenance_entry.dart';
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

/// Checks all vehicles' maintenance entries with nextServiceOdometer; when
/// vehicle odometer has reached the threshold, schedules 8 reminders (1 instant
/// + 7 daily) and marks the entry so we don't reschedule.
class CheckOdometerDueReminders {
  CheckOdometerDueReminders(
    this._vehicleRepository,
    this._maintenanceRepository,
    this._notificationService,
  );
  final VehicleRepository _vehicleRepository;
  final MaintenanceRepository _maintenanceRepository;
  final NotificationService _notificationService;

  Future<void> call() async {
    try {
      final vehicles = await _vehicleRepository.getVehicles();
      for (final vehicle in vehicles) {
        final entries =
            await _maintenanceRepository.getMaintenanceByVehicle(vehicle.id);
        for (final entry in entries) {
          if (entry.nextServiceOdometer == null ||
              entry.odometerReminderScheduled) continue;
          if (vehicle.currentOdometer < entry.nextServiceOdometer!) {
            continue;
          }
          final baseId = entry.id.hashCode & 0x7FFFFFFF;
          if (baseId < 1) {
            continue;
          }
          await _notificationService.scheduleOdometerDueReminders(
            baseId: baseId,
            title: 'Service due: ${entry.title}',
            body:
                '${vehicle.name} has reached ${entry.nextServiceOdometer} km. Time for maintenance!',
          );
          await _maintenanceRepository.updateMaintenance(
            entry.copyWith(
              notificationId: baseId,
              odometerReminderScheduled: true,
            ),
          );
        }
      }
    } catch (_) {}
  }
}
