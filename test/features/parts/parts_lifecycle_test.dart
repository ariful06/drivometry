import 'package:drivometry/features/parts/data/models/part_replacement_model.dart';
import 'package:drivometry/features/parts/domain/entities/part_replacement.dart';
import 'package:drivometry/features/parts/domain/services/parts_lifecycle_service.dart';
import 'package:flutter_test/flutter_test.dart';

PartReplacement _part({
  double? km,
  int? months,
  double installOdo = 10000,
  DateTime? installed,
  int? warranty,
  DateTime? replacedAt,
}) =>
    PartReplacement(
      id: 'p',
      vehicleId: 'v',
      partName: 'Brake pads',
      installOdometer: installOdo,
      expectedLifespanKm: km,
      lifespanMonths: months,
      installedAt: installed,
      warrantyMonths: warranty,
      replacedAt: replacedAt,
    );

void main() {
  const service = PartsLifecycleService();
  final now = DateTime(2026, 10, 15);

  test('km lifespan: ok → due soon → overdue', () {
    final part = _part(km: 20000);
    expect(service.evaluate(part, 12000, now).health, PartHealth.ok);
    expect(service.evaluate(part, 29500, now).health, PartHealth.dueSoon);
    final overdue = service.evaluate(part, 30500, now);
    expect(overdue.health, PartHealth.overdue);
    expect(overdue.remainingKm, -500);
  });

  test('month lifespan drives due state with no km set', () {
    final part = _part(months: 12, installed: DateTime(2025, 10, 20));
    final status = service.evaluate(part, 99999, now);
    expect(status.remainingDays, 5);
    expect(status.health, PartHealth.dueSoon);
    expect(service.evaluate(part, 0, DateTime(2026, 10, 21)).health,
        PartHealth.overdue);
  });

  test('whichever limit comes first wins', () {
    final part = _part(km: 50000, months: 6, installed: DateTime(2026, 1, 1));
    // km is fine, but 6 months already passed.
    expect(service.evaluate(part, 10500, now).health, PartHealth.overdue);
  });

  test('replaced parts never warn and keep their history', () {
    final part = _part(km: 1000, replacedAt: DateTime(2026, 5, 1));
    expect(service.evaluate(part, 999999, now).health, PartHealth.replaced);
    expect(service.remainingLifeKm(part, 999999), double.infinity);
  });

  test('remainingLifeKm: clamps to 0 when overdue, infinity with no lifespan',
      () {
    expect(service.remainingLifeKm(_part(km: 1000), 12000), 0);
    expect(service.remainingLifeKm(_part(km: 5000), 12000), 3000);
    expect(service.remainingLifeKm(_part(), 12000), double.infinity);
  });

  test('warranty window', () {
    final part = _part(installed: DateTime(2026, 1, 31), warranty: 12);
    expect(service.isUnderWarranty(part, DateTime(2027, 1, 31)), isTrue);
    expect(service.isUnderWarranty(part, DateTime(2027, 2, 1)), isFalse);
    expect(service.isUnderWarranty(_part(), now), isFalse);
  });

  test('due date clamps to the end of a shorter month', () {
    final part = _part(months: 1, installed: DateTime(2026, 1, 31));
    expect(service.dueDate(part), DateTime(2026, 2, 28));
  });

  test('model reads legacy rows and round-trips new fields', () {
    final legacy = PartReplacementModel.fromMap({
      'id': 'a',
      'vehicle_id': 'v',
      'part_name': 'Oil filter',
      'install_odometer': 100,
      'expected_lifespan_km': 5000,
    }).toEntity();
    expect(legacy.expectedLifespanKm, 5000);
    expect(legacy.isReplaced, isFalse);
    expect(legacy.category, isNull);

    final full = _part(
            km: 8000, months: 12, installed: DateTime(2026, 2, 3), warranty: 6)
        .copyWith(
      category: 'Brakes',
      cost: 4500,
      replacedAt: DateTime(2026, 9, 1),
      replacedById: 'next',
    );
    final back = PartReplacementModel.fromMap(
      PartReplacementModel.fromEntity(full).toMap(),
    ).toEntity();
    expect(back.category, 'Brakes');
    expect(back.lifespanMonths, 12);
    expect(back.warrantyMonths, 6);
    expect(back.cost, 4500);
    expect(back.replacedById, 'next');
    expect(back.isReplaced, isTrue);
  });
}
