import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../maintenance/domain/entities/maintenance_entry.dart';
import '../../../maintenance/domain/maintenance_notification_ids.dart';
import '../../../maintenance/domain/usecases/maintenance_usecases.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/vehicle_usecases.dart';
import '../../domain/notification_service.dart';

part 'notifications_state.dart';

/// Reminders tab only lists items inside this window (or overdue).
const int _kReminderDayWindow = 7;
const int _kReminderKmWindow = 50;

bool _withinReminderProximity(
  MaintenanceEntry maintenanceEntry,
  Map<String, Vehicle> vehiclesById,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final vehicleForEntry = vehiclesById[maintenanceEntry.vehicleId];

  bool dateNearOrOverdue() {
    final scheduledNextServiceDay = maintenanceEntry.nextServiceDate;
    if (scheduledNextServiceDay == null) return false;
    final nextDueCalendarDay = DateTime(
      scheduledNextServiceDay.year,
      scheduledNextServiceDay.month,
      scheduledNextServiceDay.day,
    );
    final daysUntilDue = nextDueCalendarDay.difference(today).inDays;
    return daysUntilDue <= _kReminderDayWindow;
  }

  bool odoNearOrOverdue() {
    final targetOdometerKm = maintenanceEntry.nextServiceOdometer;
    if (targetOdometerKm == null || vehicleForEntry == null) return false;
    final kmRemainingUntilService =
        targetOdometerKm - vehicleForEntry.currentOdometer.ceil();
    return kmRemainingUntilService <= _kReminderKmWindow;
  }

  final hasDate = maintenanceEntry.nextServiceDate != null;
  final hasOdo = maintenanceEntry.nextServiceOdometer != null;

  if (hasDate && hasOdo) {
    return dateNearOrOverdue() || odoNearOrOverdue();
  }
  if (hasDate) return dateNearOrOverdue();
  if (hasOdo) return odoNearOrOverdue();
  return false;
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required GetUpcomingMaintenance getUpcoming,
    required GetAllVehicles getAllVehicles,
    required UpdateMaintenance updateMaintenance,
    required NotificationService notificationService,
  })  : _getUpcoming = getUpcoming,
        _getAllVehicles = getAllVehicles,
        _updateMaintenance = updateMaintenance,
        _notificationService = notificationService,
        super(const NotificationsInitial());

  final GetUpcomingMaintenance _getUpcoming;
  final GetAllVehicles _getAllVehicles;
  final UpdateMaintenance _updateMaintenance;
  final NotificationService _notificationService;

  Future<void> loadUpcoming({int daysAhead = 30}) async {
    emit(const NotificationsLoading());
    try {
      final entries = await _getUpcoming(daysAhead: daysAhead);
      final vehicles = await _getAllVehicles();
      final vehiclesByIdMap = {
        for (final vehicle in vehicles) vehicle.id: vehicle,
      };
      final filteredReminderEntries =
          entries
              .where(
                (maintenanceEntry) =>
                    _withinReminderProximity(maintenanceEntry, vehiclesByIdMap),
              )
              .toList();
      emit(NotificationsLoaded(filteredReminderEntries));
    } catch (error) {
      emit(NotificationsError(error.toString()));
    }
  }

  Future<void> markReminderDone(MaintenanceEntry entry) async {
    if (entry.odometerReminderScheduled && entry.notificationId != null) {
      await _notificationService.cancelNotificationRange(
        entry.notificationId!,
        8,
      );
    } else if (entry.notificationId != null) {
      await _notificationService.cancelNotification(entry.notificationId!);
    }
    if (entry.dateProximityReminderScheduled) {
      await _notificationService.cancelNotificationRange(
        MaintenanceNotificationIds.dateBurstBase(entry.id),
        8,
      );
    }
    await _updateMaintenance(
      entry.copyWith(reminderAcknowledged: true),
    );
    await loadUpcoming(daysAhead: 60);
  }
}