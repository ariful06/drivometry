// lib/features/fuel/domain/usecases/fuel_usecases.dart

import '../../../vehicles/domain/repositories/vehicle_repository.dart';
import '../entities/fuel_entry.dart';
import '../repositories/fuel_repository.dart';
import '../services/fuel_consumption_calculator.dart';

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

/// Re-runs full-tank consumption for every fill of a vehicle and persists it.
/// Adding, editing or deleting one fill can change the periods around it.
class RecalculateFuelConsumption {
  const RecalculateFuelConsumption(this._repository, this._vehicleRepository);
  final FuelRepository _repository;
  final VehicleRepository _vehicleRepository;

  Future<void> call(String vehicleId) async {
    final entries = await _repository.getFuelEntriesByVehicle(vehicleId);
    final vehicle = await _vehicleRepository.getVehicleById(vehicleId);
    final segmentsByEntryId = FuelConsumptionCalculator.segmentsByEntryId(
      entries,
      tankCapacityLiters: vehicle?.tankCapacityLiters,
    );
    final changed = <FuelEntry>[
      for (final entry in entries)
        if (entry.fuelEfficiency != segmentsByEntryId[entry.id]?.kmPerLiter ||
            entry.calculatedMileage != segmentsByEntryId[entry.id]?.kmPerLiter)
          entry.withConsumption(segmentsByEntryId[entry.id]?.kmPerLiter),
    ];
    await _repository.updateFuelEntries(changed);
  }
}
