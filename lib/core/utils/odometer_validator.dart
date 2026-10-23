/// A dated odometer reading from any record (fuel, maintenance, ...).
class OdometerReading {
  const OdometerReading(this.date, this.odometer);

  final DateTime date;
  final double odometer;
}

enum OdometerIssue {
  /// Out of bounds or inconsistent with neighbouring readings. Blocks saving.
  error,

  /// Suspicious but allowed after confirmation.
  warning,
}

class OdometerCheck {
  const OdometerCheck(this.issue, this.message);

  final OdometerIssue issue;
  final String message;
}

/// Shared odometer / tank capacity rules for fuel and maintenance forms.
class OdometerValidator {
  const OdometerValidator._();

  static const double maxOdometer = 2000000;
  static const double minTankLiters = 1;
  static const double maxTankLiters = 200;
  static const double defaultMaxJump = 2000;

  /// Checks [odometer] on [date] against [existing] readings.
  ///
  /// Returns null when the reading looks fine.
  static OdometerCheck? validate({
    required double odometer,
    required DateTime date,
    required List<OdometerReading> existing,
    double maxJump = defaultMaxJump,
  }) {
    if (odometer < 0 || odometer > maxOdometer) {
      return const OdometerCheck(
        OdometerIssue.error,
        'Odometer must be between 0 and 2,000,000.',
      );
    }

    OdometerReading? before;
    OdometerReading? after;
    for (final r in existing) {
      if (r.date.isAfter(date)) {
        if (after == null || r.date.isBefore(after.date)) after = r;
      } else if (before == null || r.date.isAfter(before.date)) {
        before = r;
      }
    }

    if (before != null && odometer < before.odometer) {
      return OdometerCheck(
        OdometerIssue.error,
        'Odometer is lower than an earlier reading '
        '(${before.odometer.toStringAsFixed(0)}).',
      );
    }
    if (after != null && odometer > after.odometer) {
      return OdometerCheck(
        OdometerIssue.error,
        'Odometer is higher than a later reading '
        '(${after.odometer.toStringAsFixed(0)}).',
      );
    }

    final duplicate = existing.any(
      (r) =>
          r.odometer == odometer &&
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day,
    );
    if (duplicate) {
      return const OdometerCheck(
        OdometerIssue.warning,
        'A record with the same date and odometer already exists.',
      );
    }

    if (before != null && odometer - before.odometer > maxJump) {
      return OdometerCheck(
        OdometerIssue.warning,
        'That is ${(odometer - before.odometer).toStringAsFixed(0)} km '
        'since the last reading. Is it correct?',
      );
    }
    return null;
  }

  /// Vehicle odometer after a record is edited or removed.
  ///
  /// The vehicle never drops below its remaining records or [initial]. When
  /// the changed record had set [current] ([replacedOdometer] >= [current]),
  /// the reading falls back to the highest remaining record; otherwise
  /// [current] is kept (it was raised by something else, e.g. a rental).
  static double resolveCurrent({
    required double current,
    required double initial,
    required Iterable<double> remaining,
    double? replacedOdometer,
  }) {
    var highest = initial;
    for (final odometer in remaining) {
      if (odometer > highest) highest = odometer;
    }
    if (replacedOdometer != null && replacedOdometer >= current) {
      return highest;
    }
    return current > highest ? current : highest;
  }

  /// Returns an error message when [liters] is not a sane tank capacity.
  static String? validateTankCapacity(double liters) {
    if (liters < minTankLiters || liters > maxTankLiters) {
      return 'Tank capacity must be between 1 and 200 L.';
    }
    return null;
  }
}
