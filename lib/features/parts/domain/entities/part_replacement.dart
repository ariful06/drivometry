/// A spare part installed on a vehicle with expected lifespan in km.
class PartReplacement {
  const PartReplacement({
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

  PartReplacement copyWith({
    String? id,
    String? vehicleId,
    String? partName,
    double? installOdometer,
    double? expectedLifespanKm,
    DateTime? installedAt,
    double? cost,
    String? notes,
  }) =>
      PartReplacement(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        partName: partName ?? this.partName,
        installOdometer: installOdometer ?? this.installOdometer,
        expectedLifespanKm: expectedLifespanKm ?? this.expectedLifespanKm,
        installedAt: installedAt ?? this.installedAt,
        cost: cost ?? this.cost,
        notes: notes ?? this.notes,
      );
}
