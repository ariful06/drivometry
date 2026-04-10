part of 'startup_cubit.dart';

sealed class StartupState {
  const StartupState();
}

class StartupInitial extends StartupState {
  const StartupInitial();
}

class StartupLoading extends StartupState {
  const StartupLoading();
}

class StartupReady extends StartupState {
  const StartupReady(this.vehicles);
  final List<Vehicle> vehicles;

  /// Path to use as initial location: always the vehicle list.
  String get initialPath => '/vehicles';
}
