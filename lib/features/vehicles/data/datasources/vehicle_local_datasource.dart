import '../models/vehicle_model.dart';

abstract class VehicleLocalDataSource {
  Future<List<VehicleModel>> getAllVehicles();
  Future<VehicleModel?> getVehicleById(String id);
  Future<void> saveVehicle(VehicleModel model);
  Future<void> deleteVehicle(String id);
  Stream<List<VehicleModel>> watchAllVehicles();
}
