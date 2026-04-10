import '../entities/part_replacement.dart';

abstract class PartReplacementRepository {
  Future<List<PartReplacement>> getByVehicle(String vehicleId);
  Future<void> add(PartReplacement part);
  Future<void> update(PartReplacement part);
  Future<void> delete(String id);
  Stream<List<PartReplacement>> watchByVehicle(String vehicleId);
}
