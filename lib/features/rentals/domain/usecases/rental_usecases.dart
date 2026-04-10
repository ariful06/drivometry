import '../entities/rental_entry.dart';
import '../repositories/rental_repository.dart';

class GetAllRentals {
  const GetAllRentals(this._repository);
  final RentalRepository _repository;

  Future<List<RentalEntry>> call() => _repository.getAllRentals();
}

class GetRentalsByVehicle {
  const GetRentalsByVehicle(this._repository);
  final RentalRepository _repository;

  Future<List<RentalEntry>> call(String vehicleId) =>
      _repository.getRentalsByVehicle(vehicleId);
}

class AddRental {
  const AddRental(this._repository);
  final RentalRepository _repository;

  Future<void> call(RentalEntry entry) => _repository.addRental(entry);
}

class UpdateRental {
  const UpdateRental(this._repository);
  final RentalRepository _repository;

  Future<void> call(RentalEntry entry) => _repository.updateRental(entry);
}

class DeleteRental {
  const DeleteRental(this._repository);
  final RentalRepository _repository;

  Future<void> call(String id) => _repository.deleteRental(id);
}

class WatchAllRentals {
  const WatchAllRentals(this._repository);
  final RentalRepository _repository;

  Stream<List<RentalEntry>> call() => _repository.watchAllRentals();
}
