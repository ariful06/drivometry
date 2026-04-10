import '../entities/maintenance_entry.dart';

/// Domain helper for mileage-based maintenance remaining distance.
class MaintenanceService {
  const MaintenanceService();

  /// Returns remaining km until next service, or null if not mileage-based.
  /// Uses [entry].nextServiceOdometer and [currentOdometer].
  /// Returns 0 or less when due/overdue.
  int? calculateRemainingDistance(
    MaintenanceEntry entry,
    double currentOdometer,
  ) {
    final next = entry.nextServiceOdometer;
    if (next == null) return null;
    final remaining = next - currentOdometer.round();
    return remaining < 0 ? 0 : remaining;
  }
}
