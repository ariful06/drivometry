/// A spare part installed on a vehicle. Lifespan can be set in km, months, or
/// both (whichever comes first). A replaced part keeps its record
/// ([replacedAt] set) and links to its successor through [replacedById].
class PartReplacement {
  const PartReplacement({
    required this.id,
    required this.vehicleId,
    required this.partName,
    required this.installOdometer,
    this.expectedLifespanKm,
    this.lifespanMonths,
    this.category,
    this.installedAt,
    this.cost,
    this.warrantyMonths,
    this.notes,
    this.replacedAt,
    this.replacedById,
  });

  final String id;
  final String vehicleId;
  final String partName;
  final String? category;
  final double installOdometer;
  final double? expectedLifespanKm;
  final int? lifespanMonths;
  final DateTime? installedAt;
  final double? cost;
  final int? warrantyMonths;
  final String? notes;
  final DateTime? replacedAt;
  final String? replacedById;

  bool get isReplaced => replacedAt != null;

  PartReplacement copyWith({
    String? id,
    String? vehicleId,
    String? partName,
    String? category,
    double? installOdometer,
    double? expectedLifespanKm,
    int? lifespanMonths,
    DateTime? installedAt,
    double? cost,
    int? warrantyMonths,
    String? notes,
    DateTime? replacedAt,
    String? replacedById,
  }) =>
      PartReplacement(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        partName: partName ?? this.partName,
        category: category ?? this.category,
        installOdometer: installOdometer ?? this.installOdometer,
        expectedLifespanKm: expectedLifespanKm ?? this.expectedLifespanKm,
        lifespanMonths: lifespanMonths ?? this.lifespanMonths,
        installedAt: installedAt ?? this.installedAt,
        cost: cost ?? this.cost,
        warrantyMonths: warrantyMonths ?? this.warrantyMonths,
        notes: notes ?? this.notes,
        replacedAt: replacedAt ?? this.replacedAt,
        replacedById: replacedById ?? this.replacedById,
      );
}
