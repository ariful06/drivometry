import '../../domain/entities/rental_entry.dart';
import '../../domain/repositories/rental_repository.dart';
import '../datasources/rental_local_datasource.dart';
import '../models/rental_entry_model.dart';

class RentalRepositoryImpl implements RentalRepository {
  const RentalRepositoryImpl(this._dataSource);
  final RentalLocalDataSource _dataSource;

  @override
  Future<List<RentalEntry>> getAllRentals() async {
    final models = await _dataSource.getAllRentals();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<RentalEntry>> getRentalsByVehicle(String vehicleId) async {
    final models = await _dataSource.getRentalsByVehicle(vehicleId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addRental(RentalEntry entry) async {
    await _dataSource.saveRental(RentalEntryModel.fromEntity(entry));
  }

  @override
  Future<void> updateRental(RentalEntry entry) async {
    await _dataSource.saveRental(RentalEntryModel.fromEntity(entry));
  }

  @override
  Future<void> deleteRental(String id) => _dataSource.deleteRental(id);

  @override
  Stream<List<RentalEntry>> watchAllRentals() => _dataSource.watchAllRentals().map(
        (models) => models.map((m) => m.toEntity()).toList(),
      );
}
