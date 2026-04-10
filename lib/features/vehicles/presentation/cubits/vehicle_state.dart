part of 'vehicle_cubit.dart';

sealed class VehicleState {
  const VehicleState();
}

class VehicleInitial extends VehicleState {
  const VehicleInitial();
}

class VehicleLoading extends VehicleState {
  const VehicleLoading();
}

class VehicleLoaded extends VehicleState {
  const VehicleLoaded(this.vehicles);
  final List<Vehicle> vehicles;
}

class VehicleError extends VehicleState {
  const VehicleError(this.message);
  final String message;
}