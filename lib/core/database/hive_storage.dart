import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'schema_migrations.dart';

/// Hive box names. Open these in init and access via the functions below.
const String kVehiclesBox = 'vehicles';
const String kFuelEntriesBox = 'fuel_entries';
const String kMaintenanceEntriesBox = 'maintenance_entries';
const String kPartReplacementsBox = 'part_replacements';
const String kRentalEntriesBox = 'rental_entries';

/// Initializes Hive and opens all app boxes. Call once before runApp (e.g. in initDependencies).
Future<void> initHive() async {
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(kVehiclesBox);
  await Hive.openBox<dynamic>(kFuelEntriesBox);
  await Hive.openBox<dynamic>(kMaintenanceEntriesBox);
  await Hive.openBox<dynamic>(kPartReplacementsBox);
  await Hive.openBox<dynamic>(kRentalEntriesBox);
  await runMigrations(await Hive.openBox<dynamic>(kMetaBox));
  if (kDebugMode) {
    dev.log('Hive initialized and boxes opened', name: 'HiveStorage');
  }
}

/// Provides access to Hive boxes. Use after [initHive].
Box<dynamic> vehiclesBox() => Hive.box<dynamic>(kVehiclesBox);
Box<dynamic> fuelEntriesBox() => Hive.box<dynamic>(kFuelEntriesBox);
Box<dynamic> maintenanceEntriesBox() =>
    Hive.box<dynamic>(kMaintenanceEntriesBox);
Box<dynamic> partReplacementsBox() => Hive.box<dynamic>(kPartReplacementsBox);
Box<dynamic> rentalEntriesBox() => Hive.box<dynamic>(kRentalEntriesBox);
