// lib/features/fuel/domain/usecases/fuel_usecases.dart

import '../../../../core/utils/odometer_validator.dart';
import '../../../maintenance/domain/repositories/maintenance_repository.dart';
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
      capacityEnergyType: vehicle?.fuelType,
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

/// Keeps the vehicle's current odometer in line with its records after a fill
/// is edited or deleted: the max of remaining fuel and maintenance readings.
class SyncVehicleOdometer {
  const SyncVehicleOdometer(
    this._fuelRepository,
    this._maintenanceRepository,
    this._vehicleRepository,
  );
  final FuelRepository _fuelRepository;
  final MaintenanceRepository _maintenanceRepository;
  final VehicleRepository _vehicleRepository;

  /// [replacedOdometer] is the changed record's reading before the change.
  Future<void> call(String vehicleId, {double? replacedOdometer}) async {
    final vehicle = await _vehicleRepository.getVehicleById(vehicleId);
    if (vehicle == null) return;
    final fuel = await _fuelRepository.getFuelEntriesByVehicle(vehicleId);
    final maintenance =
        await _maintenanceRepository.getMaintenanceByVehicle(vehicleId);
    final odometer = OdometerValidator.resolveCurrent(
      current: vehicle.currentOdometer,
      initial: vehicle.initialOdometer,
      remaining: [
        for (final entry in fuel) entry.odometer,
        for (final entry in maintenance) entry.odometer,
        if (vehicle.manualOdometer case final manual?) manual,
      ],
      replacedOdometer: replacedOdometer,
    );
    if (odometer != vehicle.currentOdometer) {
      await _vehicleRepository
          .updateVehicle(vehicle.copyWith(currentOdometer: odometer));
    }
  }
}

/// Saves an edited fill, then recalculates consumption and the odometer.
class EditFuelEntry {
  const EditFuelEntry(this._repository, this._recalculate, this._syncOdometer);
  final FuelRepository _repository;
  final RecalculateFuelConsumption _recalculate;
  final SyncVehicleOdometer _syncOdometer;

  Future<void> call(FuelEntry entry) async {
    final saved = await _repository.getFuelEntriesByVehicle(entry.vehicleId);
    final before = saved.where((e) => e.id == entry.id).firstOrNull;
    await _repository.updateFuelEntry(entry);
    await _recalculate(entry.vehicleId);
    await _syncOdometer(entry.vehicleId, replacedOdometer: before?.odometer);
  }
}

/// Deletes a fill, then recalculates consumption and the odometer.
class RemoveFuelEntry {
  const RemoveFuelEntry(
    this._repository,
    this._recalculate,
    this._syncOdometer,
  );
  final FuelRepository _repository;
  final RecalculateFuelConsumption _recalculate;
  final SyncVehicleOdometer _syncOdometer;

  Future<void> call(FuelEntry entry) async {
    await _repository.deleteFuelEntry(entry.id);
    await _recalculate(entry.vehicleId);
    await _syncOdometer(entry.vehicleId, replacedOdometer: entry.odometer);
  }
}
