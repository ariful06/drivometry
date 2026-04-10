// lib/features/vehicles/domain/repositories/vehicle_repository.dart

import '../entities/vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getAllVehicles();
  /// Alias for [getAllVehicles]. Use for startup / routing.
  Future<List<Vehicle>> getVehicles() => getAllVehicles();
  Future<Vehicle?> getVehicleById(String id);
  Future<void> addVehicle(Vehicle vehicle);
  Future<void> updateVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(String id);
  Stream<List<Vehicle>> watchAllVehicles();
}
