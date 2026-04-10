part of 'maintenance_cubit.dart';

sealed class MaintenanceState {
  const MaintenanceState();
}

class MaintenanceInitial extends MaintenanceState {
  const MaintenanceInitial();
}

class MaintenanceLoading extends MaintenanceState {
  const MaintenanceLoading();
}

class MaintenanceLoaded extends MaintenanceState {
  const MaintenanceLoaded(this.entries);
  final List<MaintenanceEntry> entries;
}

class MaintenanceError extends MaintenanceState {
  const MaintenanceError(this.message);
  final String message;
}