import '../../domain/entities/part_replacement.dart';

/// Map (de)serialisation for [PartReplacement]. Rows written before the
/// lifecycle fields existed still load: every new key is optional.
class PartReplacementModel {
  const PartReplacementModel(this.entity);
  final PartReplacement entity;

  String get id => entity.id;
  double get installOdometer => entity.installOdometer;

  factory PartReplacementModel.fromEntity(PartReplacement e) =>
      PartReplacementModel(e);

  PartReplacement toEntity() => entity;

  factory PartReplacementModel.fromMap(Map<String, dynamic> map) {
    DateTime? date(String key) =>
        map[key] != null ? DateTime.parse(map[key] as String) : null;
    double? number(String key) => (map[key] as num?)?.toDouble();
    return PartReplacementModel(PartReplacement(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      partName: map['part_name'] as String,
      category: map['category'] as String?,
      installOdometer: (map['install_odometer'] as num).toDouble(),
      expectedLifespanKm: number('expected_lifespan_km'),
      lifespanMonths: (map['lifespan_months'] as num?)?.toInt(),
      installedAt: date('installed_at'),
      cost: number('cost'),
      warrantyMonths: (map['warranty_months'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      replacedAt: date('replaced_at'),
      replacedById: map['replaced_by_id'] as String?,
    ));
  }

  Map<String, dynamic> toMap() => {
        'id': entity.id,
        'vehicle_id': entity.vehicleId,
        'part_name': entity.partName,
        'category': entity.category,
        'install_odometer': entity.installOdometer,
        'expected_lifespan_km': entity.expectedLifespanKm,
        'lifespan_months': entity.lifespanMonths,
        'installed_at': entity.installedAt?.toIso8601String(),
        'cost': entity.cost,
        'warranty_months': entity.warrantyMonths,
        'notes': entity.notes,
        'replaced_at': entity.replacedAt?.toIso8601String(),
        'replaced_by_id': entity.replacedById,
      };
}
