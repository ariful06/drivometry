import '../../domain/entities/part_replacement.dart';
import '../../domain/repositories/part_replacement_repository.dart';
import '../datasources/part_replacement_local_datasource.dart';
import '../models/part_replacement_model.dart';

class PartReplacementRepositoryImpl implements PartReplacementRepository {
  const PartReplacementRepositoryImpl(this._dataSource);
  final PartReplacementLocalDataSource _dataSource;

  @override
  Future<List<PartReplacement>> getByVehicle(String vehicleId) async {
    final models = await _dataSource.getByVehicle(vehicleId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> add(PartReplacement part) async {
    await _dataSource.save(PartReplacementModel.fromEntity(part));
  }

  @override
  Future<void> update(PartReplacement part) async {
    await _dataSource.save(PartReplacementModel.fromEntity(part));
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Stream<List<PartReplacement>> watchByVehicle(String vehicleId) =>
      _dataSource.watchByVehicle(vehicleId).map(
            (models) => models.map((m) => m.toEntity()).toList(),
          );
}
