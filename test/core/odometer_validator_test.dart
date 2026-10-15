import 'package:drivometry/core/utils/odometer_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final jan = DateTime(2026, 1, 10);
  final feb = DateTime(2026, 2, 10);
  final mar = DateTime(2026, 3, 10);
  final existing = [OdometerReading(jan, 1000), OdometerReading(mar, 1500)];

  OdometerCheck? check(double odo, DateTime d, [double? jump]) =>
      OdometerValidator.validate(
        odometer: odo,
        date: d,
        existing: existing,
        maxJump: jump ?? OdometerValidator.defaultMaxJump,
      );

  test('valid reading between neighbours passes', () {
    expect(check(1200, feb), isNull);
  });

  test('lower than earlier reading is an error', () {
    expect(check(900, feb)?.issue, OdometerIssue.error);
  });

  test('higher than later reading is an error', () {
    expect(check(1600, feb)?.issue, OdometerIssue.error);
  });

  test('out of bounds is an error', () {
    expect(check(-1, feb)?.issue, OdometerIssue.error);
    expect(check(3000000, DateTime(2027, 1, 1))?.issue, OdometerIssue.error);
  });

  test('same date and odometer is a duplicate warning', () {
    expect(check(1000, jan)?.issue, OdometerIssue.warning);
  });

  test('large jump is a warning', () {
    expect(check(1200, feb, 100)?.issue, OdometerIssue.warning);
  });

  test('first reading with no history passes', () {
    expect(
      OdometerValidator.validate(odometer: 50, date: jan, existing: const []),
      isNull,
    );
  });

  test('tank capacity bounds', () {
    expect(OdometerValidator.validateTankCapacity(40), isNull);
    expect(OdometerValidator.validateTankCapacity(0.5), isNotNull);
    expect(OdometerValidator.validateTankCapacity(4533333), isNotNull);
  });
}
