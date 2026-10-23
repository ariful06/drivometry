import '../entities/part_replacement.dart';

enum PartHealth { ok, dueSoon, overdue, replaced }

class PartStatus {
  const PartStatus({
    required this.health,
    this.remainingKm,
    this.remainingDays,
    this.usedFraction,
  });

  final PartHealth health;

  /// Negative when past the km limit; null when no km lifespan is set.
  final double? remainingKm;

  /// Negative when past the date limit; null when no month lifespan is set.
  final int? remainingDays;

  /// 0 = new, 1 = at the limit (the worse of km / time); null if no lifespan.
  final double? usedFraction;
}

/// Domain helper for spare-part wear, due state and warranty.
class PartsLifecycleService {
  const PartsLifecycleService();

  /// Remaining life in km: (installOdometer + expectedLifespanKm) - currentOdometer.
  /// Returns 0 when at or past replacement due, and infinity when the part has
  /// no km lifespan or has already been replaced (so it never raises a warning).
  double remainingLifeKm(PartReplacement part, double currentOdometer) {
    final lifespan = part.expectedLifespanKm;
    if (part.isReplaced || lifespan == null) return double.infinity;
    final remaining = part.installOdometer + lifespan - currentOdometer;
    return remaining < 0 ? 0 : remaining;
  }

  /// Due date derived from the install date and month lifespan.
  DateTime? dueDate(PartReplacement part) {
    final installed = part.installedAt;
    final months = part.lifespanMonths;
    if (installed == null || months == null) return null;
    return _addMonths(installed, months);
  }

  PartStatus evaluate(
    PartReplacement part,
    double currentOdometer,
    DateTime now, {
    double soonKm = 1000,
    int soonDays = 30,
    double soonFraction = 0.9,
  }) {
    if (part.isReplaced) return const PartStatus(health: PartHealth.replaced);

    double? remainingKm;
    double? kmFraction;
    final lifespanKm = part.expectedLifespanKm;
    if (lifespanKm != null && lifespanKm > 0) {
      remainingKm = part.installOdometer + lifespanKm - currentOdometer;
      kmFraction = (currentOdometer - part.installOdometer) / lifespanKm;
    }

    int? remainingDays;
    double? timeFraction;
    final due = dueDate(part);
    if (due != null) {
      final today = DateTime(now.year, now.month, now.day);
      remainingDays =
          DateTime(due.year, due.month, due.day).difference(today).inDays;
      final total = due.difference(part.installedAt!).inDays;
      if (total > 0) {
        timeFraction = (total - remainingDays) / total;
      }
    }

    final fractions = [kmFraction, timeFraction].whereType<double>();
    final used =
        fractions.isEmpty ? null : fractions.reduce((a, b) => a > b ? a : b);

    final overdue = (remainingKm != null && remainingKm <= 0) ||
        (remainingDays != null && remainingDays <= 0);
    final soon = (remainingKm != null && remainingKm <= soonKm) ||
        (remainingDays != null && remainingDays <= soonDays) ||
        (used != null && used >= soonFraction);

    return PartStatus(
      health: overdue
          ? PartHealth.overdue
          : soon
              ? PartHealth.dueSoon
              : PartHealth.ok,
      remainingKm: remainingKm,
      remainingDays: remainingDays,
      usedFraction: used,
    );
  }

  bool isUnderWarranty(PartReplacement part, DateTime now) {
    final installed = part.installedAt;
    final months = part.warrantyMonths;
    if (installed == null || months == null) return false;
    return !now.isAfter(_addMonths(installed, months));
  }

  static DateTime _addMonths(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(
        target.year, target.month, date.day > lastDay ? lastDay : date.day);
  }
}
