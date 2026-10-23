import 'package:hive_flutter/hive_flutter.dart';

import 'hive_storage.dart';

const String kMetaBox = 'meta';
const String _schemaVersionKey = 'schema_version';

/// Current data schema version. Bump it and add an entry to [kMigrations]
/// whenever stored data needs a one-time upgrade.
const int kSchemaVersion = 2;

/// Migrations keyed by the version they upgrade *to*. Each runs once, in order.
final Map<int, Future<void> Function()> kMigrations = {
  2: () => stampEnergyTypes(
        fuelEntries: Hive.box<dynamic>(kFuelEntriesBox),
        vehicles: Hive.box<dynamic>(kVehiclesBox),
      ),
};

/// v2: fills and vehicles get an explicit energy type. Everything recorded
/// before then was petrol in litres. Existing values are kept, so re-running
/// is a no-op.
Future<void> stampEnergyTypes({
  required Box<dynamic> fuelEntries,
  required Box<dynamic> vehicles,
}) async {
  Future<void> stamp(Box<dynamic> box, String key) async {
    final updates = <dynamic, Map<String, dynamic>>{};
    for (final id in box.keys) {
      final row = box.get(id);
      if (row is Map && row[key] == null) {
        updates[id] = {...Map<String, dynamic>.from(row), key: 'petrol'};
      }
    }
    await box.putAll(updates);
  }

  await stamp(fuelEntries, 'energy_type');
  await stamp(vehicles, 'fuel_type');
}

/// Runs pending migrations on [meta] up to [target], saving progress after each
/// step so a failure resumes from the last good version.
Future<void> runMigrations(
  Box<dynamic> meta, {
  int target = kSchemaVersion,
  Map<int, Future<void> Function()>? migrations,
}) async {
  final steps = migrations ?? kMigrations;
  var current = (meta.get(_schemaVersionKey) as int?) ?? 0;
  while (current < target) {
    final next = current + 1;
    await steps[next]?.call();
    await meta.put(_schemaVersionKey, next);
    current = next;
  }
}
