import '../models/part_replacement_model.dart';

abstract class PartReplacementLocalDataSource {
  Future<List<PartReplacementModel>> getByVehicle(String vehicleId);
  Future<void> save(PartReplacementModel model);
  Future<void> delete(String id);
  Stream<List<PartReplacementModel>> watchByVehicle(String vehicleId);
}
