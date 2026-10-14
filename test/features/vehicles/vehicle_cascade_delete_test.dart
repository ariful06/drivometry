import 'dart:io';

import 'package:drivometry/core/database/hive_storage.dart';
import 'package:drivometry/features/vehicles/data/datasources/vehicle_hive_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_cascade');
    Hive.init(dir.path);
    for (final name in [
      kVehiclesBox,
      kFuelEntriesBox,
      kMaintenanceEntriesBox,
      kPartReplacementsBox,
      kRentalEntriesBox,
    ]) {
      await Hive.openBox<dynamic>(name);
    }
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test("deleteVehicle removes only that vehicle's related records", () async {
    await fuelEntriesBox().put('f1', {'vehicle_id': 'a'});
    await fuelEntriesBox().put('f2', {'vehicle_id': 'b'});
    await maintenanceEntriesBox().put('m1', {'vehicle_id': 'a'});
    await partReplacementsBox().put('p1', {'vehicle_id': 'a'});
    await rentalEntriesBox().put('r1', {'vehicle_id': 'a'});
    await vehiclesBox().put('a', {'id': 'a'});

    await VehicleHiveDataSource().deleteVehicle('a');

    expect(vehiclesBox().containsKey('a'), isFalse);
    expect(fuelEntriesBox().keys.toList(), ['f2']);
    expect(maintenanceEntriesBox().isEmpty, isTrue);
    expect(partReplacementsBox().isEmpty, isTrue);
    expect(rentalEntriesBox().isEmpty, isTrue);
  });
}
