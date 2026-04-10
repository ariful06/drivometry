// lib/features/vehicles/data/repositories/vehicle_repository_impl.dart

import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_local_datasource.dart';
import '../models/vehicle_model.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  const VehicleRepositoryImpl(this._dataSource);
  final VehicleLocalDataSource _dataSource;

  @override
  Future<List<Vehicle>> getAllVehicles() async {
    final models = await _dataSource.getAllVehicles();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Vehicle>> getVehicles() => getAllVehicles();

  @override
  Future<Vehicle?> getVehicleById(String id) async {
    final model = await _dataSource.getVehicleById(id);
    return model?.toEntity();
  }

  @override
  Future<void> addVehicle(Vehicle vehicle) async {
    await _dataSource.saveVehicle(VehicleModel.fromEntity(vehicle));
  }

  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    await _dataSource.saveVehicle(VehicleModel.fromEntity(vehicle));
  }

  @override
  Future<void> deleteVehicle(String id) => _dataSource.deleteVehicle(id);

  @override
  Stream<List<Vehicle>> watchAllVehicles() =>
      _dataSource.watchAllVehicles().map(
            (models) => models.map((m) => m.toEntity()).toList(),
          );
}
