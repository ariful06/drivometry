import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../notifications/domain/notification_service.dart';
import '../../domain/entities/maintenance_entry.dart';
import '../../domain/usecases/maintenance_usecases.dart';

part 'maintenance_state.dart';

class MaintenanceCubit extends Cubit<MaintenanceState> {
  MaintenanceCubit({
    required WatchMaintenanceByVehicle watchMaintenance,
    required AddMaintenance addMaintenance,
    required UpdateMaintenance updateMaintenance,
    required DeleteMaintenance deleteMaintenance,
    required GetUpcomingMaintenance getUpcoming,
    required NotificationService notificationService,
  })  : _watchMaintenance = watchMaintenance,
        _addMaintenance = addMaintenance,
        _updateMaintenance = updateMaintenance,
        _deleteMaintenance = deleteMaintenance,
        _getUpcoming = getUpcoming,
        _notificationService = notificationService,
        super(const MaintenanceInitial());

  final WatchMaintenanceByVehicle _watchMaintenance;
  final AddMaintenance _addMaintenance;
  final UpdateMaintenance _updateMaintenance;
  final DeleteMaintenance _deleteMaintenance;
  final GetUpcomingMaintenance _getUpcoming;
  final NotificationService _notificationService;
  StreamSubscription<List<MaintenanceEntry>>? _subscription;

  void watchForVehicle(String vehicleId) {
    emit(const MaintenanceLoading());
    _subscription?.cancel();
    _subscription = _watchMaintenance(vehicleId).listen(
          (entries) => emit(MaintenanceLoaded(entries)),
      onError: (Object e) => emit(MaintenanceError(e.toString())),
    );
  }

  Future<void> addMaintenance({
    required String vehicleId,
    required String type,
    required String title,
    required String description,
    required double cost,
    required double odometer,
    required DateTime serviceDate,
    DateTime? nextServiceDate,
    int? nextServiceOdometer,
    String? notes,
  }) async {
    try {
      int? notificationId;
      if (nextServiceDate != null) {
        final reminderDate = nextServiceDate.subtract(const Duration(days: 1));
        if (reminderDate.isAfter(DateTime.now())) {
          notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await _notificationService.scheduleMaintenanceReminder(
            id: notificationId,
            title: 'Upcoming Service: $title',
            body: 'Service due tomorrow!',
            scheduledDate: reminderDate,
          );
        }
      }
      final entry = MaintenanceEntry(
        id: const Uuid().v4(),
        vehicleId: vehicleId,
        type: type,
        title: title,
        description: description,
        cost: cost,
        odometer: odometer,
        serviceDate: serviceDate,
        nextServiceDate: nextServiceDate,
        nextServiceOdometer: nextServiceOdometer,
        notes: notes,
        notificationId: notificationId,
      );
      await _addMaintenance(entry);
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> deleteMaintenance(
    String id, {
    int? notificationId,
    bool odometerReminderScheduled = false,
  }) async {
    try {
      if (notificationId != null) {
        if (odometerReminderScheduled) {
          await _notificationService.cancelNotificationRange(
            notificationId,
            8,
          );
        } else {
          await _notificationService.cancelNotification(notificationId);
        }
      }
      await _deleteMaintenance(id);
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<List<MaintenanceEntry>> getUpcoming() => _getUpcoming(daysAhead: 30);

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}