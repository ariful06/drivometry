import '../models/rental_entry_model.dart';

abstract class RentalLocalDataSource {
  Future<List<RentalEntryModel>> getAllRentals();
  Future<List<RentalEntryModel>> getRentalsByVehicle(String vehicleId);
  Future<void> saveRental(RentalEntryModel model);
  Future<void> deleteRental(String id);
  Stream<List<RentalEntryModel>> watchAllRentals();
}
