import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/vehicle_usecases.dart';

part 'vehicle_state.dart';

class VehicleCubit extends Cubit<VehicleState> {
  VehicleCubit({
    required WatchAllVehicles watchAllVehicles,
    required AddVehicle addVehicle,
    required UpdateVehicle updateVehicle,
    required DeleteVehicle deleteVehicle,
  })  : _watchAllVehicles = watchAllVehicles,
        _addVehicle = addVehicle,
        _updateVehicle = updateVehicle,
        _deleteVehicle = deleteVehicle,
        super(const VehicleInitial());

  final WatchAllVehicles _watchAllVehicles;
  final AddVehicle _addVehicle;
  final UpdateVehicle _updateVehicle;
  final DeleteVehicle _deleteVehicle;
  StreamSubscription<List<Vehicle>>? _subscription;

  void startWatching() {
    emit(const VehicleLoading());
    _subscription = _watchAllVehicles().listen(
      (vehicles) => emit(VehicleLoaded(vehicles)),
      onError: (Object error) => emit(VehicleError(error.toString())),
    );
  }

  Future<void> addVehicle({
    required String name,
    required String type,
    required String make,
    required String model,
    required int year,
    required String licensePlate,
    required double initialOdometer,
    String? color,
    String? notes,
  }) async {
    try {
      final vehicle = Vehicle(
        id: const Uuid().v4(),
        name: name,
        type: type,
        make: make,
        model: model,
        year: year,
        licensePlate: licensePlate,
        initialOdometer: initialOdometer,
        currentOdometer: initialOdometer,
        createdAt: DateTime.now(),
        color: color,
        notes: notes,
        isRental: false,
      );
      await _addVehicle(vehicle);
    } catch (error) {
      emit(VehicleError(error.toString()));
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _updateVehicle(vehicle);
    } catch (error) {
      emit(VehicleError(error.toString()));
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await _deleteVehicle(id);
    } catch (error) {
      emit(VehicleError(error.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
