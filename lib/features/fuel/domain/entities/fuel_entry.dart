class FuelEntry {
  const FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.costPerLiter,
    required this.totalCost,
    this.notes,
    this.fuelEfficiency,
    this.distanceDriven,
    this.tripDistance,
    this.isFullTank = false,
    this.calculatedMileage,
    this.receiptImagePath,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final double odometer;
  final double liters;
  final double costPerLiter;
  final double totalCost;
  final String? notes;
  final double? fuelEfficiency;
  final double? distanceDriven;
  /// Trip meter distance (km) for this fill-up when isFullTank is true.
  final double? tripDistance;
  final bool isFullTank;
  /// When isFullTank: tripDistance / liters (km/L).
  final double? calculatedMileage;
  /// Optional path to receipt image in app storage.
  final String? receiptImagePath;

  FuelEntry copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    double? odometer,
    double? liters,
    double? costPerLiter,
    double? totalCost,
    String? notes,
    double? fuelEfficiency,
    double? distanceDriven,
    double? tripDistance,
    bool? isFullTank,
    double? calculatedMileage,
    String? receiptImagePath,
  }) => FuelEntry(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    date: date ?? this.date,
    odometer: odometer ?? this.odometer,
    liters: liters ?? this.liters,
    costPerLiter: costPerLiter ?? this.costPerLiter,
    totalCost: totalCost ?? this.totalCost,
    notes: notes ?? this.notes,
    fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
    distanceDriven: distanceDriven ?? this.distanceDriven,
    tripDistance: tripDistance ?? this.tripDistance,
    isFullTank: isFullTank ?? this.isFullTank,
    calculatedMileage: calculatedMileage ?? this.calculatedMileage,
    receiptImagePath: receiptImagePath ?? this.receiptImagePath,
  );
}