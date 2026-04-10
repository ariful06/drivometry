// lib/features/fuel/data/models/fuel_entry_model.dart

import '../../domain/entities/fuel_entry.dart';

class FuelEntryModel {
  const FuelEntryModel({
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
  final double? tripDistance;
  final bool isFullTank;
  final double? calculatedMileage;
  final String? receiptImagePath;

  factory FuelEntryModel.fromMap(Map<String, dynamic> map) => FuelEntryModel(
        id: map['id'] as String,
        vehicleId: map['vehicle_id'] as String,
        date: DateTime.parse(map['date'] as String),
        odometer: (map['odometer'] as num).toDouble(),
        liters: (map['liters'] as num).toDouble(),
        costPerLiter: (map['cost_per_liter'] as num).toDouble(),
        totalCost: (map['total_cost'] as num).toDouble(),
        notes: map['notes'] as String?,
        fuelEfficiency: map['fuel_efficiency'] != null
            ? (map['fuel_efficiency'] as num).toDouble()
            : null,
        distanceDriven: map['distance_driven'] != null
            ? (map['distance_driven'] as num).toDouble()
            : null,
        tripDistance: map['trip_distance'] != null
            ? (map['trip_distance'] as num).toDouble()
            : null,
        isFullTank: (map['is_full_tank'] as int?) == 1,
        calculatedMileage: map['calculated_mileage'] != null
            ? (map['calculated_mileage'] as num).toDouble()
            : null,
        receiptImagePath: map['receipt_image_path'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'date': date.toIso8601String(),
        'odometer': odometer,
        'liters': liters,
        'cost_per_liter': costPerLiter,
        'total_cost': totalCost,
        'notes': notes,
        'fuel_efficiency': fuelEfficiency,
        'distance_driven': distanceDriven,
        'trip_distance': tripDistance,
        'is_full_tank': isFullTank ? 1 : 0,
        'calculated_mileage': calculatedMileage,
        'receipt_image_path': receiptImagePath,
      };

  factory FuelEntryModel.fromEntity(FuelEntry e) => FuelEntryModel(
        id: e.id,
        vehicleId: e.vehicleId,
        date: e.date,
        odometer: e.odometer,
        liters: e.liters,
        costPerLiter: e.costPerLiter,
        totalCost: e.totalCost,
        notes: e.notes,
        fuelEfficiency: e.fuelEfficiency,
        distanceDriven: e.distanceDriven,
        tripDistance: e.tripDistance,
        isFullTank: e.isFullTank,
        calculatedMileage: e.calculatedMileage,
        receiptImagePath: e.receiptImagePath,
      );

  FuelEntry toEntity() => FuelEntry(
        id: id,
        vehicleId: vehicleId,
        date: date,
        odometer: odometer,
        liters: liters,
        costPerLiter: costPerLiter,
        totalCost: totalCost,
        notes: notes,
        fuelEfficiency: fuelEfficiency,
        distanceDriven: distanceDriven,
        tripDistance: tripDistance,
        isFullTank: isFullTank,
        calculatedMileage: calculatedMileage,
        receiptImagePath: receiptImagePath,
      );
}