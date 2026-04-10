// lib/features/fuel/domain/repositories/fuel_repository.dart

import '../entities/fuel_entry.dart';

abstract class FuelRepository {
  Future<List<FuelEntry>> getFuelEntriesByVehicle(String vehicleId);
  Future<FuelEntry?> getLastFuelEntry(String vehicleId);
  Future<void> addFuelEntry(FuelEntry entry);
  Future<void> updateFuelEntry(FuelEntry entry);
  Future<void> deleteFuelEntry(String id);
  Stream<List<FuelEntry>> watchFuelEntriesByVehicle(String vehicleId);
  Future<double> getTotalFuelCostByVehicle(String vehicleId);
  Future<double> getTotalFuelCostInRange(DateTime from, DateTime to);
  Future<double> getTotalFuelCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  );
}
