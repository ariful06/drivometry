import '../entities/part_replacement.dart';

/// Domain helper for spare parts remaining life (km).
class PartsLifecycleService {
  const PartsLifecycleService();

  /// Remaining life in km: (installOdometer + expectedLifespanKm) - currentOdometer.
  /// Returns 0 when at or past replacement due.
  double remainingLifeKm(PartReplacement part, double currentOdometer) {
    final dueAt = part.installOdometer + part.expectedLifespanKm;
    final remaining = dueAt - currentOdometer;
    return remaining < 0 ? 0 : remaining;
  }
}
