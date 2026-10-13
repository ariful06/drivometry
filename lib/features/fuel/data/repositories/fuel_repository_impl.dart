// lib/features/fuel/data/repositories/fuel_repository_impl.dart

import '../../domain/entities/fuel_entry.dart';
import '../../domain/repositories/fuel_repository.dart';
import '../datasources/fuel_local_datasource.dart';
import '../models/fuel_entry_model.dart';

class FuelRepositoryImpl implements FuelRepository {
  const FuelRepositoryImpl(this._dataSource);
  final FuelLocalDataSource _dataSource;

  @override
  Future<List<FuelEntry>> getFuelEntriesByVehicle(String vehicleId) async {
    final models = await _dataSource.getFuelEntriesByVehicle(vehicleId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<FuelEntry?> getLastFuelEntry(String vehicleId) async {
    final model = await _dataSource.getLastFuelEntry(vehicleId);
    return model?.toEntity();
  }

  @override
  Future<void> addFuelEntry(FuelEntry entry) async {
    await _dataSource.saveFuelEntry(FuelEntryModel.fromEntity(entry));
  }

  @override
  Future<void> updateFuelEntry(FuelEntry entry) async {
    await _dataSource.saveFuelEntry(FuelEntryModel.fromEntity(entry));
  }

  @override
  Future<void> updateFuelEntries(List<FuelEntry> entries) =>
      _dataSource.saveFuelEntries(
        entries.map(FuelEntryModel.fromEntity).toList(),
      );

  @override
  Future<void> deleteFuelEntry(String id) => _dataSource.deleteFuelEntry(id);

  @override
  Stream<List<FuelEntry>> watchFuelEntriesByVehicle(String vehicleId) =>
      _dataSource.watchFuelEntriesByVehicle(vehicleId).map(
            (models) => models.map((m) => m.toEntity()).toList(),
          );

  @override
  Future<double> getTotalFuelCostByVehicle(String vehicleId) =>
      _dataSource.getTotalFuelCostByVehicle(vehicleId);

  @override
  Future<double> getTotalFuelCostInRange(DateTime from, DateTime to) =>
      _dataSource.getTotalFuelCostInRange(from, to);

  @override
  Future<double> getTotalFuelCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  ) =>
      _dataSource.getTotalFuelCostByVehicleInRange(vehicleId, from, to);
}
