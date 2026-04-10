import '../models/fuel_entry_model.dart';

abstract class FuelLocalDataSource {
  Future<List<FuelEntryModel>> getFuelEntriesByVehicle(String vehicleId);
  Future<FuelEntryModel?> getLastFuelEntry(String vehicleId);
  Future<void> saveFuelEntry(FuelEntryModel model);
  Future<void> deleteFuelEntry(String id);
  Stream<List<FuelEntryModel>> watchFuelEntriesByVehicle(String vehicleId);
  Future<double> getTotalFuelCostByVehicle(String vehicleId);
  Future<double> getTotalFuelCostInRange(DateTime from, DateTime to);
  Future<double> getTotalFuelCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  );
}
