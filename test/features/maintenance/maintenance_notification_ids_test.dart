import 'package:drivometry/features/maintenance/domain/maintenance_notification_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FNV-1a ids match known values (stable across runs)', () {
    // FNV-1a('abc') = 0x1A47E90B; & 0x7FFFFFFF keeps it unchanged.
    expect(MaintenanceNotificationIds.odometerBurstBase('abc'), 0x1A47E90B);
    expect(
      MaintenanceNotificationIds.dateBurstBase('abc'),
      (0x1A47E90B ^ 0xBADC0FFE) & 0x7FFFFFFF,
    );
  });

  test('ids are positive and differ per kind', () {
    const id = '5f1c2b9e-0000-4000-8000-123456789abc';
    final o = MaintenanceNotificationIds.odometerBurstBase(id);
    final d = MaintenanceNotificationIds.dateBurstBase(id);
    expect(o, greaterThan(0));
    expect(d, greaterThan(0));
    expect(o, isNot(d));
  });
}
