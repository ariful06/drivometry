class MaintenanceEntry {
  const MaintenanceEntry({
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
  /// True after we've scheduled the 8 daily reminders for nextServiceOdometer.
  final bool odometerReminderScheduled;

  MaintenanceEntry copyWith({
    String? id,
    String? vehicleId,
    String? type,
    String? title,
    String? description,
    double? cost,
    double? odometer,
    DateTime? serviceDate,
    DateTime? nextServiceDate,
    int? nextServiceOdometer,
    String? notes,
    int? notificationId,
    bool? odometerReminderScheduled,
  }) => MaintenanceEntry(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    type: type ?? this.type,
    title: title ?? this.title,
    description: description ?? this.description,
    cost: cost ?? this.cost,
    odometer: odometer ?? this.odometer,
    serviceDate: serviceDate ?? this.serviceDate,
    nextServiceDate: nextServiceDate ?? this.nextServiceDate,
    nextServiceOdometer: nextServiceOdometer ?? this.nextServiceOdometer,
    notes: notes ?? this.notes,
    notificationId: notificationId ?? this.notificationId,
    odometerReminderScheduled:
        odometerReminderScheduled ?? this.odometerReminderScheduled,
  );
}