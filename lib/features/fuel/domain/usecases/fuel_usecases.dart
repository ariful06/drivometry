// lib/features/fuel/domain/usecases/fuel_usecases.dart

import '../entities/fuel_entry.dart';
import '../repositories/fuel_repository.dart';

class GetFuelEntriesByVehicle {
  const GetFuelEntriesByVehicle(this._repository);
  final FuelRepository _repository;

  Future<List<FuelEntry>> call(String vehicleId) =>
      _repository.getFuelEntriesByVehicle(vehicleId);
}

class GetLastFuelEntry {
  const GetLastFuelEntry(this._repository);
  final FuelRepository _repository;

  Future<FuelEntry?> call(String vehicleId) =>
      _repository.getLastFuelEntry(vehicleId);
}

class AddFuelEntry {
  const AddFuelEntry(this._repository);
  final FuelRepository _repository;

  Future<void> call(FuelEntry entry) => _repository.addFuelEntry(entry);
}

class UpdateFuelEntry {
  const UpdateFuelEntry(this._repository);
  final FuelRepository _repository;

  Future<void> call(FuelEntry entry) => _repository.updateFuelEntry(entry);
}

class DeleteFuelEntry {
  const DeleteFuelEntry(this._repository);
  final FuelRepository _repository;

  Future<void> call(String id) => _repository.deleteFuelEntry(id);
}

class WatchFuelEntriesByVehicle {
  const WatchFuelEntriesByVehicle(this._repository);
  final FuelRepository _repository;

  Stream<List<FuelEntry>> call(String vehicleId) =>
      _repository.watchFuelEntriesByVehicle(vehicleId);
}

class GetTotalFuelCostByVehicle {
  const GetTotalFuelCostByVehicle(this._repository);
  final FuelRepository _repository;

  Future<double> call(String vehicleId) =>
      _repository.getTotalFuelCostByVehicle(vehicleId);
}
