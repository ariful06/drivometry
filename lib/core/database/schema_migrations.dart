import 'package:hive_flutter/hive_flutter.dart';

const String kMetaBox = 'meta';
const String _schemaVersionKey = 'schema_version';

/// Current data schema version. Bump it and add an entry to [kMigrations]
/// whenever stored data needs a one-time upgrade.
const int kSchemaVersion = 1;

/// Migrations keyed by the version they upgrade *to*. Each runs once, in order.
final Map<int, Future<void> Function()> kMigrations = {};

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
