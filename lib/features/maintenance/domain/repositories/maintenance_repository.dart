// lib/features/maintenance/domain/repositories/maintenance_repository.dart

import '../entities/maintenance_entry.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceEntry>> getMaintenanceByVehicle(String vehicleId);
  Future<List<MaintenanceEntry>> getUpcomingMaintenance({int daysAhead = 7});
  Future<void> addMaintenance(MaintenanceEntry entry);
  Future<void> updateMaintenance(MaintenanceEntry entry);
  Future<void> deleteMaintenance(String id);
  Stream<List<MaintenanceEntry>> watchMaintenanceByVehicle(String vehicleId);

  /// Fires after any maintenance add/update/delete (all vehicles).
  Stream<void> watchMaintenanceChanges();
  Future<double> getTotalMaintenanceCostByVehicle(String vehicleId);
  Future<double> getTotalMaintenanceCostInRange(DateTime from, DateTime to);
  Future<double> getTotalMaintenanceCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  );
}
