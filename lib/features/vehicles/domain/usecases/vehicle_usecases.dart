// lib/features/vehicles/domain/usecases/vehicle_usecases.dart

import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

class GetAllVehicles {
  const GetAllVehicles(this._repository);
  final VehicleRepository _repository;

  Future<List<Vehicle>> call() => _repository.getAllVehicles();
}

class GetVehicleById {
  const GetVehicleById(this._repository);
  final VehicleRepository _repository;

  Future<Vehicle?> call(String id) => _repository.getVehicleById(id);
}

class AddVehicle {
  const AddVehicle(this._repository);
  final VehicleRepository _repository;

  Future<void> call(Vehicle vehicle) => _repository.addVehicle(vehicle);
}

class UpdateVehicle {
  const UpdateVehicle(this._repository);
  final VehicleRepository _repository;

  Future<void> call(Vehicle vehicle) => _repository.updateVehicle(vehicle);
}

class DeleteVehicle {
  const DeleteVehicle(this._repository);
  final VehicleRepository _repository;

  Future<void> call(String id) => _repository.deleteVehicle(id);
}

class WatchAllVehicles {
  const WatchAllVehicles(this._repository);
  final VehicleRepository _repository;

  Stream<List<Vehicle>> call() => _repository.watchAllVehicles();
}
