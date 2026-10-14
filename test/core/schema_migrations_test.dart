import 'dart:io';

import 'package:drivometry/core/database/schema_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory dir;
  late Box<dynamic> meta;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_meta');
    Hive.init(dir.path);
    meta = await Hive.openBox<dynamic>(kMetaBox);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('runs pending migrations once, in order', () async {
    final ran = <int>[];
    final steps = {
      1: () async => ran.add(1),
      2: () async => ran.add(2),
      3: () async => ran.add(3),
    };
    await runMigrations(meta, target: 3, migrations: steps);
    expect(ran, [1, 2, 3]);
    expect(meta.get('schema_version'), 3);

    await runMigrations(meta, target: 3, migrations: steps);
    expect(ran, [1, 2, 3]);
  });

  test('failed step keeps last good version', () async {
    final steps = {
      1: () async {},
      2: () async => throw StateError('boom'),
    };
    await expectLater(
      runMigrations(meta, target: 2, migrations: steps),
      throwsStateError,
    );
    expect(meta.get('schema_version'), 1);
  });
}
