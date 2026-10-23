// lib/features/vehicles/domain/usecases/vehicle_usecases.dart

import '../../../../core/utils/odometer_validator.dart';
import '../../../fuel/domain/repositories/fuel_repository.dart';
import '../../../maintenance/domain/repositories/maintenance_repository.dart';
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

/// Sets the vehicle's odometer without logging a fill-up, so distance-based
/// reminders stay current. Readings never go below the vehicle's records.
class UpdateVehicleOdometer {
  const UpdateVehicleOdometer(
    this._vehicleRepository,
    this._fuelRepository,
    this._maintenanceRepository, {
    Future<void> Function()? onUpdated,
  }) : _onUpdated = onUpdated;

  final VehicleRepository _vehicleRepository;
  final FuelRepository _fuelRepository;
  final MaintenanceRepository _maintenanceRepository;

  /// Runs after saving, e.g. maintenance reminder checks.
  final Future<void> Function()? _onUpdated;

  /// Returns null when [odometer] can be saved as-is.
  Future<OdometerCheck?> check(Vehicle vehicle, double odometer) async {
    if (odometer < vehicle.currentOdometer) {
      return OdometerCheck(
        OdometerIssue.error,
        'Odometer is lower than the saved reading '
        '(${vehicle.currentOdometer.toStringAsFixed(0)}).',
      );
    }
    final fuel = await _fuelRepository.getFuelEntriesByVehicle(vehicle.id);
    final maintenance = await _maintenanceRepository.getMaintenanceByVehicle(
      vehicle.id,
    );
    return OdometerValidator.validate(
      odometer: odometer,
      date: DateTime.now(),
      existing: [
        OdometerReading(DateTime(1970), vehicle.currentOdometer),
        for (final entry in fuel) OdometerReading(entry.date, entry.odometer),
        for (final entry in maintenance)
          OdometerReading(entry.serviceDate, entry.odometer),
      ],
    );
  }

  /// Saves [odometer]; call [check] first. Returns the updated vehicle.
  Future<Vehicle> call(Vehicle vehicle, double odometer) async {
    final updated = vehicle.copyWith(currentOdometer: odometer);
    await _vehicleRepository.updateVehicle(updated);
    await _onUpdated?.call();
    return updated;
  }
}
