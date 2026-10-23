import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:drivometry/features/maintenance/domain/entities/maintenance_entry.dart';
import 'package:drivometry/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/features/vehicles/domain/repositories/vehicle_repository.dart';

class InMemoryFuelRepository implements FuelRepository {
  InMemoryFuelRepository(List<FuelEntry> seed)
      : entries = {for (final e in seed) e.id: e};

  final Map<String, FuelEntry> entries;

  List<FuelEntry> _byVehicle(String vehicleId) =>
      entries.values.where((e) => e.vehicleId == vehicleId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<List<FuelEntry>> getFuelEntriesByVehicle(String vehicleId) async =>
      _byVehicle(vehicleId);

  @override
  Future<FuelEntry?> getLastFuelEntry(String vehicleId) async {
    final list = _byVehicle(vehicleId);
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<void> addFuelEntry(FuelEntry entry) async => entries[entry.id] = entry;

  @override
  Future<void> updateFuelEntry(FuelEntry entry) async =>
      entries[entry.id] = entry;

  @override
  Future<void> updateFuelEntries(List<FuelEntry> batch) async {
    for (final entry in batch) {
      entries[entry.id] = entry;
    }
  }

  @override
  Future<void> deleteFuelEntry(String id) async => entries.remove(id);

  @override
  Stream<List<FuelEntry>> watchFuelEntriesByVehicle(String vehicleId) =>
      Stream.value(_byVehicle(vehicleId));

  @override
  Future<double> getTotalFuelCostByVehicle(String vehicleId) async => 0;

  @override
  Future<double> getTotalFuelCostInRange(DateTime from, DateTime to) async => 0;

  @override
  Future<double> getTotalFuelCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  ) async =>
      0;
}

class InMemoryVehicleRepository extends VehicleRepository {
  InMemoryVehicleRepository(this.vehicle);
  final Vehicle vehicle;
  Vehicle? updated;

  @override
  Future<void> updateVehicle(Vehicle vehicle) async => updated = vehicle;

  @override
  Future<List<Vehicle>> getAllVehicles() async => const [];
  @override
  Future<Vehicle?> getVehicleById(String id) async => updated ?? vehicle;
  @override
  Future<void> addVehicle(Vehicle vehicle) async {}
  @override
  Future<void> deleteVehicle(String id) async {}
  @override
  Stream<List<Vehicle>> watchAllVehicles() => const Stream.empty();
}

/// Only [getMaintenanceByVehicle] is used by fuel code.
class InMemoryMaintenanceRepository implements MaintenanceRepository {
  InMemoryMaintenanceRepository([this.entries = const []]);
  final List<MaintenanceEntry> entries;

  @override
  Future<List<MaintenanceEntry>> getMaintenanceByVehicle(
    String vehicleId,
  ) async =>
      entries.where((e) => e.vehicleId == vehicleId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Vehicle testVehicle({double? tankCapacity = 45, double odometer = 1200}) =>
    Vehicle(
      id: 'v1',
      name: 'Test car',
      type: 'Car',
      make: 'Toyota',
      model: 'Axio',
      year: 2020,
      licensePlate: 'DHA-1',
      initialOdometer: 0,
      currentOdometer: odometer,
      createdAt: DateTime(2026),
      tankCapacityLiters: tankCapacity,
    );

FuelEntry savedFill(
  String id,
  double odometer,
  double liters, {
  required bool full,
  required int day,
  double? tripDistance,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: DateTime(2026, 9, day),
      odometer: odometer,
      liters: liters,
      costPerLiter: 100,
      totalCost: liters * 100,
      isFullTank: full,
      tripDistance: tripDistance,
    );
