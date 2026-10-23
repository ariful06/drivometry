import '../../../../core/constants/energy_type.dart';

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
    this.missedPreviousFill = false,
    this.fuelLevelPercent,
    this.energyType = EnergyType.petrol,
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

  /// Trip meter distance (km) since the previous fill, when logged in trip mode.
  final double? tripDistance;

  /// Tank was filled to the brim. Consumption is only measured between full tanks.
  final bool isFullTank;

  /// Full-tank consumption (km/L) for the period this fill closes; null for
  /// partial fills and unmeasurable periods. See `FuelConsumptionCalculator`.
  final double? calculatedMileage;

  /// Optional path to receipt image in app storage.
  final String? receiptImagePath;

  /// A fill-up before this one was not logged, so the period up to this fill
  /// cannot be measured.
  final bool missedPreviousFill;

  /// Fuel gauge level (0–100 %) right after a partial fill, if recorded. Lets
  /// consumption be estimated from tank capacity when no full tank is logged.
  final double? fuelLevelPercent;

  /// What was filled; [liters] and [costPerLiter] are in this type's unit
  /// (L, kg or kWh) despite their names.
  final EnergyType energyType;

  /// Copy with stored consumption replaced (allows clearing to null).
  FuelEntry withConsumption(double? kmPerLiter) => FuelEntry(
        id: id,
        vehicleId: vehicleId,
        date: date,
        odometer: odometer,
        liters: liters,
        costPerLiter: costPerLiter,
        totalCost: totalCost,
        notes: notes,
        fuelEfficiency: kmPerLiter,
        distanceDriven: distanceDriven,
        tripDistance: tripDistance,
        isFullTank: isFullTank,
        calculatedMileage: kmPerLiter,
        receiptImagePath: receiptImagePath,
        missedPreviousFill: missedPreviousFill,
        fuelLevelPercent: fuelLevelPercent,
        energyType: energyType,
      );

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
    bool? missedPreviousFill,
    double? fuelLevelPercent,
    EnergyType? energyType,
  }) =>
      FuelEntry(
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
        missedPreviousFill: missedPreviousFill ?? this.missedPreviousFill,
        fuelLevelPercent: fuelLevelPercent ?? this.fuelLevelPercent,
        energyType: energyType ?? this.energyType,
      );
}
