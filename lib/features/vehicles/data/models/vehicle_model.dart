// lib/features/vehicles/data/models/vehicle_model.dart

import '../../domain/entities/vehicle.dart';

class VehicleModel {
  const VehicleModel({
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
    this.manualOdometer,
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
  final double? tankCapacityLiters;
  final String? registrationImagePath;
  final String? taxTokenImagePath;
  final String? fitnessImagePath;
  final DateTime? fitnessExpiryDate;
  final bool isRental;
  final double? manualOdometer;

  factory VehicleModel.fromMap(Map<String, dynamic> map) => VehicleModel(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        make: map['make'] as String,
        model: map['model'] as String,
        year: map['year'] as int,
        licensePlate: map['license_plate'] as String,
        initialOdometer: (map['initial_odometer'] as num).toDouble(),
        currentOdometer: (map['current_odometer'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        color: map['color'] as String?,
        notes: map['notes'] as String?,
        tankCapacityLiters: map['tank_capacity_liters'] != null
            ? (map['tank_capacity_liters'] as num).toDouble()
            : null,
        registrationImagePath: map['registration_image_path'] as String?,
        taxTokenImagePath: map['tax_token_image_path'] as String?,
        fitnessImagePath: map['fitness_image_path'] as String?,
        fitnessExpiryDate: map['fitness_expiry_date'] != null
            ? DateTime.parse(map['fitness_expiry_date'] as String)
            : null,
        isRental: (map['is_rental'] as int?) == 1,
        manualOdometer: (map['manual_odometer'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'make': make,
        'model': model,
        'year': year,
        'license_plate': licensePlate,
        'initial_odometer': initialOdometer,
        'current_odometer': currentOdometer,
        'created_at': createdAt.toIso8601String(),
        'color': color,
        'notes': notes,
        'tank_capacity_liters': tankCapacityLiters,
        'registration_image_path': registrationImagePath,
        'tax_token_image_path': taxTokenImagePath,
        'fitness_image_path': fitnessImagePath,
        'fitness_expiry_date': fitnessExpiryDate?.toIso8601String(),
        'is_rental': isRental ? 1 : 0,
        'manual_odometer': manualOdometer,
      };

  factory VehicleModel.fromEntity(Vehicle e) => VehicleModel(
        id: e.id,
        name: e.name,
        type: e.type,
        make: e.make,
        model: e.model,
        year: e.year,
        licensePlate: e.licensePlate,
        initialOdometer: e.initialOdometer,
        currentOdometer: e.currentOdometer,
        createdAt: e.createdAt,
        color: e.color,
        notes: e.notes,
        tankCapacityLiters: e.tankCapacityLiters,
        registrationImagePath: e.registrationImagePath,
        taxTokenImagePath: e.taxTokenImagePath,
        fitnessImagePath: e.fitnessImagePath,
        fitnessExpiryDate: e.fitnessExpiryDate,
        isRental: e.isRental,
        manualOdometer: e.manualOdometer,
      );

  Vehicle toEntity() => Vehicle(
        id: id,
        name: name,
        type: type,
        make: make,
        model: model,
        year: year,
        licensePlate: licensePlate,
        initialOdometer: initialOdometer,
        currentOdometer: currentOdometer,
        createdAt: createdAt,
        color: color,
        notes: notes,
        tankCapacityLiters: tankCapacityLiters,
        registrationImagePath: registrationImagePath,
        taxTokenImagePath: taxTokenImagePath,
        fitnessImagePath: fitnessImagePath,
        fitnessExpiryDate: fitnessExpiryDate,
        isRental: isRental,
        manualOdometer: manualOdometer,
      );
}
