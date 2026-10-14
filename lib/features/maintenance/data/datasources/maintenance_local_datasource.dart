import '../models/maintenance_entry_model.dart';

abstract class MaintenanceLocalDataSource {
  Future<List<MaintenanceEntryModel>> getMaintenanceByVehicle(String vehicleId);
  Future<List<MaintenanceEntryModel>> getUpcomingMaintenance(
      {int daysAhead = 7});
  Future<void> saveMaintenance(MaintenanceEntryModel model);
  Future<void> deleteMaintenance(String id);
  Stream<List<MaintenanceEntryModel>> watchMaintenanceByVehicle(
    String vehicleId,
  );

  /// Emits after any write to the maintenance store (all vehicles).
  Stream<void> watchMaintenanceStore();
  Future<double> getTotalCostByVehicle(String vehicleId);
  Future<double> getTotalCostInRange(DateTime from, DateTime to);
  Future<double> getTotalCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  );
}
