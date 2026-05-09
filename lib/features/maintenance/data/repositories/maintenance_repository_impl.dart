// lib/features/maintenance/data/repositories/maintenance_repository_impl.dart

import '../../domain/entities/maintenance_entry.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../datasources/maintenance_local_datasource.dart';
import '../models/maintenance_entry_model.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  const MaintenanceRepositoryImpl(this._dataSource);
  final MaintenanceLocalDataSource _dataSource;

  @override
  Future<List<MaintenanceEntry>> getMaintenanceByVehicle(
    String vehicleId,
  ) async {
    final models = await _dataSource.getMaintenanceByVehicle(vehicleId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<MaintenanceEntry>> getUpcomingMaintenance({
    int daysAhead = 7,
  }) async {
    final models =
        await _dataSource.getUpcomingMaintenance(daysAhead: daysAhead);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addMaintenance(MaintenanceEntry entry) async {
    await _dataSource.saveMaintenance(
      MaintenanceEntryModel.fromEntity(entry),
    );
  }

  @override
  Future<void> updateMaintenance(MaintenanceEntry entry) async {
    await _dataSource.saveMaintenance(
      MaintenanceEntryModel.fromEntity(entry),
    );
  }

  @override
  Future<void> deleteMaintenance(String id) =>
      _dataSource.deleteMaintenance(id);

  @override
  Stream<List<MaintenanceEntry>> watchMaintenanceByVehicle(
    String vehicleId,
  ) =>
      _dataSource.watchMaintenanceByVehicle(vehicleId).map(
            (models) => models.map((m) => m.toEntity()).toList(),
          );

  @override
  Stream<void> watchMaintenanceChanges() =>
      _dataSource.watchMaintenanceStore();

  @override
  Future<double> getTotalMaintenanceCostByVehicle(String vehicleId) =>
      _dataSource.getTotalCostByVehicle(vehicleId);

  @override
  Future<double> getTotalMaintenanceCostInRange(DateTime from, DateTime to) =>
      _dataSource.getTotalCostInRange(from, to);

  @override
  Future<double> getTotalMaintenanceCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  ) =>
      _dataSource.getTotalCostByVehicleInRange(vehicleId, from, to);
}
