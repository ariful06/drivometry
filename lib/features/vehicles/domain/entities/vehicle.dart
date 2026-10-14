class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.initialOdometer,
    required this.currentOdometer,
    required this.createdAt,
    this.color,
    this.notes,
    this.tankCapacityLiters,
    this.registrationImagePath,
    this.taxTokenImagePath,
    this.fitnessImagePath,
    this.fitnessExpiryDate,
    this.isRental = false,
  });

  final String id;
  final String name;
  final String type;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final double initialOdometer;
  final double currentOdometer;
  final DateTime createdAt;
  final String? color;
  final String? notes;

  /// Fuel tank capacity in liters (optional).
  final double? tankCapacityLiters;

  /// Local file path for registration document image (optional).
  final String? registrationImagePath;

  /// Local file path for tax token image (optional).
  final String? taxTokenImagePath;

  /// Local file path for fitness certificate image (Car / Other only).
  final String? fitnessImagePath;

  /// Fitness certificate expiry date (Car / Other only).
  final DateTime? fitnessExpiryDate;

  /// True when the vehicle is used for rental / fleet; false for personal use.
  final bool isRental;

  Vehicle copyWith({
    String? id,
    String? name,
    String? type,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    double? initialOdometer,
    double? currentOdometer,
    DateTime? createdAt,
    String? color,
    String? notes,
    double? tankCapacityLiters,
    String? registrationImagePath,
    String? taxTokenImagePath,
    String? fitnessImagePath,
    DateTime? fitnessExpiryDate,
    bool? isRental,
  }) =>
      Vehicle(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        make: make ?? this.make,
        model: model ?? this.model,
        year: year ?? this.year,
        licensePlate: licensePlate ?? this.licensePlate,
        initialOdometer: initialOdometer ?? this.initialOdometer,
        currentOdometer: currentOdometer ?? this.currentOdometer,
        createdAt: createdAt ?? this.createdAt,
        color: color ?? this.color,
        notes: notes ?? this.notes,
        tankCapacityLiters: tankCapacityLiters ?? this.tankCapacityLiters,
        registrationImagePath:
            registrationImagePath ?? this.registrationImagePath,
        taxTokenImagePath: taxTokenImagePath ?? this.taxTokenImagePath,
        fitnessImagePath: fitnessImagePath ?? this.fitnessImagePath,
        fitnessExpiryDate: fitnessExpiryDate ?? this.fitnessExpiryDate,
        isRental: isRental ?? this.isRental,
      );
}
