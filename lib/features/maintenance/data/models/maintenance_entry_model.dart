// lib/features/maintenance/data/models/maintenance_entry_model.dart

import '../../domain/entities/maintenance_entry.dart';

class MaintenanceEntryModel {
  const MaintenanceEntryModel({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.title,
    required this.description,
    required this.cost,
    required this.odometer,
    required this.serviceDate,
    this.nextServiceDate,
    this.nextServiceOdometer,
    this.notes,
    this.notificationId,
    this.odometerReminderScheduled = false,
    this.dateProximityReminderScheduled = false,
    this.reminderAcknowledged = false,
  });

  final String id;
  final String vehicleId;
  final String type;
  final String title;
  final String description;
  final double cost;
  final double odometer;
  final DateTime serviceDate;
  final DateTime? nextServiceDate;
  final int? nextServiceOdometer;
  final String? notes;
  final int? notificationId;
  final bool odometerReminderScheduled;
  final bool dateProximityReminderScheduled;
  final bool reminderAcknowledged;

  factory MaintenanceEntryModel.fromMap(Map<String, dynamic> map) =>
      MaintenanceEntryModel(
        id: map['id'] as String,
        vehicleId: map['vehicle_id'] as String,
        type: map['type'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        cost: (map['cost'] as num).toDouble(),
        odometer: (map['odometer'] as num).toDouble(),
        serviceDate: DateTime.parse(map['service_date'] as String),
        nextServiceDate: map['next_service_date'] != null
            ? DateTime.parse(map['next_service_date'] as String)
            : null,
        nextServiceOdometer: map['next_service_odometer'] as int?,
        notes: map['notes'] as String?,
        notificationId: map['notification_id'] as int?,
        odometerReminderScheduled:
            map['odometer_reminder_scheduled'] as bool? ?? false,
        dateProximityReminderScheduled:
            map['date_proximity_reminder_scheduled'] as bool? ?? false,
        reminderAcknowledged: map['reminder_acknowledged'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'type': type,
        'title': title,
        'description': description,
        'cost': cost,
        'odometer': odometer,
        'service_date': serviceDate.toIso8601String(),
        'next_service_date': nextServiceDate?.toIso8601String(),
        'next_service_odometer': nextServiceOdometer,
        'notes': notes,
        'notification_id': notificationId,
        'odometer_reminder_scheduled': odometerReminderScheduled,
        'date_proximity_reminder_scheduled': dateProximityReminderScheduled,
        'reminder_acknowledged': reminderAcknowledged,
      };

  factory MaintenanceEntryModel.fromEntity(MaintenanceEntry e) =>
      MaintenanceEntryModel(
        id: e.id,
        vehicleId: e.vehicleId,
        type: e.type,
        title: e.title,
        description: e.description,
        cost: e.cost,
        odometer: e.odometer,
        serviceDate: e.serviceDate,
        nextServiceDate: e.nextServiceDate,
        nextServiceOdometer: e.nextServiceOdometer,
        notes: e.notes,
        notificationId: e.notificationId,
        odometerReminderScheduled: e.odometerReminderScheduled,
        dateProximityReminderScheduled: e.dateProximityReminderScheduled,
        reminderAcknowledged: e.reminderAcknowledged,
      );

  MaintenanceEntry toEntity() => MaintenanceEntry(
        id: id,
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
        odometerReminderScheduled: odometerReminderScheduled,
        dateProximityReminderScheduled: dateProximityReminderScheduled,
        reminderAcknowledged: reminderAcknowledged,
      );
}
