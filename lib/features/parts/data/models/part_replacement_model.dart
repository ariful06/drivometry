import '../../domain/entities/part_replacement.dart';

class PartReplacementModel {
  const PartReplacementModel({
    required this.id,
    required this.vehicleId,
    required this.partName,
    required this.installOdometer,
    required this.expectedLifespanKm,
    this.installedAt,
    this.cost,
    this.notes,
  });

  final String id;
  final String vehicleId;
  final String partName;
  final double installOdometer;
  final double expectedLifespanKm;
  final DateTime? installedAt;
  final double? cost;
  final String? notes;

  factory PartReplacementModel.fromMap(Map<String, dynamic> map) =>
      PartReplacementModel(
        id: map['id'] as String,
        vehicleId: map['vehicle_id'] as String,
        partName: map['part_name'] as String,
        installOdometer: (map['install_odometer'] as num).toDouble(),
        expectedLifespanKm: (map['expected_lifespan_km'] as num).toDouble(),
        installedAt: map['installed_at'] != null
            ? DateTime.parse(map['installed_at'] as String)
            : null,
        cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'part_name': partName,
        'install_odometer': installOdometer,
        'expected_lifespan_km': expectedLifespanKm,
        'installed_at': installedAt?.toIso8601String(),
        'cost': cost,
        'notes': notes,
      };

  factory PartReplacementModel.fromEntity(PartReplacement e) =>
      PartReplacementModel(
        id: e.id,
        vehicleId: e.vehicleId,
        partName: e.partName,
        installOdometer: e.installOdometer,
        expectedLifespanKm: e.expectedLifespanKm,
        installedAt: e.installedAt,
        cost: e.cost,
        notes: e.notes,
      );

  PartReplacement toEntity() => PartReplacement(
        id: id,
        vehicleId: vehicleId,
        partName: partName,
        installOdometer: installOdometer,
        expectedLifespanKm: expectedLifespanKm,
        installedAt: installedAt,
        cost: cost,
        notes: notes,
      );
}
