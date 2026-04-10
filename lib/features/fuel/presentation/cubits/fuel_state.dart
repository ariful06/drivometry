part of 'fuel_cubit.dart';

sealed class FuelState {
  const FuelState();
}

class FuelInitial extends FuelState {
  const FuelInitial();
}

class FuelLoading extends FuelState {
  const FuelLoading();
}

class FuelLoaded extends FuelState {
  const FuelLoaded({required this.entries, required this.totalCost});
  final List<FuelEntry> entries;
  final double totalCost;
}

class FuelError extends FuelState {
  const FuelError(this.message);
  final String message;
}