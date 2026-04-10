import '../entities/rental_entry.dart';

abstract class RentalRepository {
  Future<List<RentalEntry>> getAllRentals();
  Future<List<RentalEntry>> getRentalsByVehicle(String vehicleId);
  Future<void> addRental(RentalEntry entry);
  Future<void> updateRental(RentalEntry entry);
  Future<void> deleteRental(String id);
  Stream<List<RentalEntry>> watchAllRentals();
}
