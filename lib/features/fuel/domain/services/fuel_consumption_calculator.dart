// lib/features/fuel/domain/services/fuel_consumption_calculator.dart

import '../../../../core/constants/energy_type.dart';
import '../entities/fuel_entry.dart';

/// One measured consumption period, attributed to the fill that closes it.
class FuelConsumptionSegment {
  const FuelConsumptionSegment({
    required this.startEntryId,
    required this.endEntryId,
    required this.distanceKm,
    required this.liters,
    required this.fillCount,
    this.isEstimated = false,
    this.energyType = EnergyType.petrol,
  });

  /// Fill that opened the period (its liters are NOT counted).
  final String startEntryId;

  /// Fill that closed the period; consumption is attributed to it.
  final String endEntryId;

  /// Odometer delta across the period.
  final double distanceKm;

  /// Fuel burned in the period.
  final double liters;

  /// Number of fills summed into [liters] (1 = no partial fills in between).
  final int fillCount;

  /// Derived from tank capacity × fuel-gauge levels instead of a full-to-full
  /// chain (no full-tank baseline was available).
  final bool isEstimated;

  /// Fuel measured; [liters] and [kmPerLiter] are in its unit (L, kg, kWh).
  final EnergyType energyType;

  double get kmPerLiter => distanceKm / liters;

  double get litersPer100Km => liters / distanceKm * 100;

  bool get includesPartialFills => fillCount > 1;
}

/// Fuel consumption the way fuel-log apps (Fuelio, Fuelly, Drivvo) compute it.
///
/// Fills are processed oldest → newest (by date, then odometer) as a queue:
///
/// 1. **Full-to-full** — a full tank closes the period opened by the previous
///    full tank: `(odo − prevFullOdo) / liters`, where liters are this fill's.
/// 2. **Partial fills** — a fill with `isFullTank == false` only queues its
///    liters; they are added to the next full tank's liters, and the distance
///    spans from the previous full tank. No value is produced for the partial.
/// 3. **Estimate fallback** — with no full-tank baseline (before the first full
///    tank, or after a chain break), two consecutive fills whose gauge level
///    after filling is known (full tank = 100 %) give
///    `used = capacity × prevLevel + liters − capacity × currentLevel`.
/// 4. **Energy types** — each fuel of a bi-fuel vehicle (e.g. petrol + CNG)
///    is its own chain; fills of one type never close a period of another.
///    Tank capacity applies to `capacityEnergyType` (all types when null).
/// 5. **Chain break** — [FuelEntry.missedPreviousFill] or an odometer that does
///    not increase (reset / replaced cluster / typo) discards the queue and
///    restarts measuring; history before the break is left untouched.
abstract final class FuelConsumptionCalculator {
  /// Oldest → newest by date, then odometer for same-day fills.
  static List<FuelEntry> sortChronologically(Iterable<FuelEntry> entries) {
    return entries.toList()
      ..sort((left, right) {
        final byDate = left.date.compareTo(right.date);
        return byDate != 0 ? byDate : left.odometer.compareTo(right.odometer);
      });
  }

  /// All measurable periods, oldest first.
  static List<FuelConsumptionSegment> segments(
    Iterable<FuelEntry> entries, {
    double? tankCapacityLiters,
    EnergyType? capacityEnergyType,
  }) {
    final ordered = sortChronologically(entries);
    final position = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i,
    };
    final byType = <EnergyType, List<FuelEntry>>{};
    for (final entry in ordered) {
      byType.putIfAbsent(entry.energyType, () => []).add(entry);
    }
    final result = <FuelConsumptionSegment>[
      for (final MapEntry(key: type, value: group) in byType.entries)
        ..._segmentsOfOneType(
          group,
          type,
          capacityEnergyType == null || capacityEnergyType == type
              ? tankCapacityLiters
              : null,
        ),
    ]..sort(
        (left, right) =>
            position[left.endEntryId]!.compareTo(position[right.endEntryId]!),
      );
    return result;
  }

  static List<FuelConsumptionSegment> _segmentsOfOneType(
    List<FuelEntry> entries,
    EnergyType energyType,
    double? tankCapacityLiters,
  ) {
    final result = <FuelConsumptionSegment>[];
    final capacity = (tankCapacityLiters ?? 0) > 0 ? tankCapacityLiters : null;

    FuelEntry? previous;
    FuelEntry? openingFullTank;
    var queuedLiters = 0.0;
    var queuedFills = 0;

    for (final entry in entries) {
      final chainBroken = entry.missedPreviousFill ||
          (previous != null && entry.odometer <= previous.odometer);
      if (chainBroken) {
        previous = null;
        openingFullTank = null;
      }

      if (openingFullTank != null) {
        queuedLiters += entry.liters;
        queuedFills++;
        if (entry.isFullTank) {
          final distanceKm = entry.odometer - openingFullTank.odometer;
          if (distanceKm > 0 && queuedLiters > 0) {
            result.add(
              FuelConsumptionSegment(
                startEntryId: openingFullTank.id,
                endEntryId: entry.id,
                distanceKm: distanceKm,
                liters: queuedLiters,
                fillCount: queuedFills,
                energyType: energyType,
              ),
            );
          }
        }
      } else if (previous != null && capacity != null) {
        final estimated = _estimate(previous, entry, capacity);
        if (estimated != null) result.add(estimated);
      }

      if (entry.isFullTank) {
        openingFullTank = entry;
        queuedLiters = 0;
        queuedFills = 0;
      }
      previous = entry;
    }
    return result;
  }

  static FuelConsumptionSegment? _estimate(
    FuelEntry previous,
    FuelEntry current,
    double capacity,
  ) {
    final previousLevel = _levelAfterFillPercent(previous);
    final currentLevel = _levelAfterFillPercent(current);
    if (previousLevel == null || currentLevel == null) return null;
    final distanceKm = current.odometer - previous.odometer;
    final litersUsed = capacity * previousLevel / 100 +
        current.liters -
        capacity * currentLevel / 100;
    if (distanceKm <= 0 || litersUsed <= 0) return null;
    return FuelConsumptionSegment(
      startEntryId: previous.id,
      endEntryId: current.id,
      distanceKm: distanceKm,
      liters: litersUsed,
      fillCount: 1,
      isEstimated: true,
      energyType: current.energyType,
    );
  }

  static double? _levelAfterFillPercent(FuelEntry entry) {
    if (entry.isFullTank) return 100;
    final level = entry.fuelLevelPercent;
    if (level == null || level < 0 || level > 100) return null;
    return level;
  }

  /// Measured period keyed by the closing fill's id.
  static Map<String, FuelConsumptionSegment> segmentsByEntryId(
    Iterable<FuelEntry> entries, {
    double? tankCapacityLiters,
    EnergyType? capacityEnergyType,
  }) {
    return byEndEntryId(
      segments(
        entries,
        tankCapacityLiters: tankCapacityLiters,
        capacityEnergyType: capacityEnergyType,
      ),
    );
  }

  static Map<String, FuelConsumptionSegment> byEndEntryId(
    Iterable<FuelConsumptionSegment> segments,
  ) {
    return {for (final segment in segments) segment.endEntryId: segment};
  }

  /// Distance-weighted average over all measured periods of [energyType]
  /// (total km ÷ total amount, not a mean of per-fill values). Null
  /// [energyType] averages every period, which only makes sense when all
  /// fills share one unit.
  static double? averageKmPerLiter(
    Iterable<FuelEntry> entries, {
    double? tankCapacityLiters,
    EnergyType? capacityEnergyType,
    EnergyType? energyType,
  }) {
    var distanceKm = 0.0;
    var liters = 0.0;
    for (final segment in segments(
      entries,
      tankCapacityLiters: tankCapacityLiters,
      capacityEnergyType: capacityEnergyType,
    )) {
      if (energyType != null && segment.energyType != energyType) continue;
      distanceKm += segment.distanceKm;
      liters += segment.liters;
    }
    return liters > 0 ? distanceKm / liters : null;
  }

  /// Consumption the [draft] fill would close, given the saved [history].
  static FuelConsumptionSegment? previewForDraft(
    Iterable<FuelEntry> history,
    FuelEntry draft, {
    double? tankCapacityLiters,
    EnergyType? capacityEnergyType,
  }) {
    return segmentsByEntryId(
      [...history, draft],
      tankCapacityLiters: tankCapacityLiters,
      capacityEnergyType: capacityEnergyType,
    )[draft.id];
  }
}
