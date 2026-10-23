// lib/injection_container.dart
//
// Dependency injection: only this file binds concrete data-layer implementations
// (datasources, repository impls) to the app. The rest of the app depends on
// domain interfaces (e.g. VehicleRepository). To swap the data layer (e.g. to
// Hive), replace the *DataSource and/or *RepositoryImpl registrations below;
// see docs/ARCHITECTURE.md.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get_it/get_it.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzl;

import 'core/database/hive_storage.dart';
import 'core/services/performance_service.dart';
import 'features/analytics/presentation/cubits/analytics_cubit.dart';
import 'features/fuel/data/datasources/fuel_hive_datasource.dart';
import 'features/fuel/data/datasources/fuel_local_datasource.dart';
import 'features/fuel/data/repositories/fuel_repository_impl.dart';
import 'features/fuel/domain/repositories/fuel_repository.dart';
import 'features/fuel/domain/usecases/fuel_usecases.dart';
import 'features/fuel/presentation/cubits/fuel_cubit.dart';
import 'features/maintenance/data/datasources/maintenance_hive_datasource.dart';
import 'features/maintenance/data/datasources/maintenance_local_datasource.dart';
import 'features/maintenance/data/repositories/maintenance_repository_impl.dart';
import 'features/maintenance/domain/repositories/maintenance_repository.dart';
import 'features/maintenance/domain/services/maintenance_service.dart';
import 'features/maintenance/domain/usecases/maintenance_usecases.dart';
import 'features/maintenance/presentation/cubits/maintenance_cubit.dart';
import 'features/notifications/domain/notification_service.dart';
import 'features/parts/data/datasources/part_replacement_hive_datasource.dart';
import 'features/parts/data/datasources/part_replacement_local_datasource.dart';
import 'features/parts/data/repositories/part_replacement_repository_impl.dart';
import 'features/parts/domain/repositories/part_replacement_repository.dart';
import 'features/parts/domain/services/parts_lifecycle_service.dart';
import 'features/rentals/data/datasources/rental_hive_datasource.dart';
import 'features/rentals/data/datasources/rental_local_datasource.dart';
import 'features/rentals/data/repositories/rental_repository_impl.dart';
import 'features/rentals/domain/repositories/rental_repository.dart';
import 'features/rentals/domain/usecases/rental_usecases.dart';
import 'features/rentals/presentation/cubits/rental_cubit.dart';
import 'features/startup/presentation/cubits/startup_cubit.dart';
import 'features/vehicles/data/datasources/vehicle_hive_datasource.dart';
import 'features/vehicles/data/datasources/vehicle_local_datasource.dart';
import 'features/vehicles/data/repositories/vehicle_repository_impl.dart';
import 'features/vehicles/domain/repositories/vehicle_repository.dart';
import 'features/vehicles/domain/usecases/vehicle_usecases.dart';
import 'features/vehicles/presentation/cubits/vehicle_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  tz.initializeTimeZones();
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    tzl.setLocalLocation(tzl.getLocation(zone.identifier));
  } catch (_) {
    // Fall back to UTC if the device zone is unknown.
  }
  await initHive();
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  sl.registerSingleton<FlutterLocalNotificationsPlugin>(notificationsPlugin);
  sl.registerSingleton<NotificationService>(
    NotificationServiceImpl(sl<FlutterLocalNotificationsPlugin>()),
  );
  await sl<NotificationService>().initialize();

  sl.registerLazySingleton<VehicleLocalDataSource>(
    () => VehicleHiveDataSource(),
  );
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(sl<VehicleLocalDataSource>()),
  );
  sl.registerLazySingleton(() => GetAllVehicles(sl<VehicleRepository>()));
  sl.registerLazySingleton(() => GetVehicleById(sl<VehicleRepository>()));
  sl.registerLazySingleton(() => AddVehicle(sl<VehicleRepository>()));
  sl.registerLazySingleton(() => UpdateVehicle(sl<VehicleRepository>()));
  sl.registerLazySingleton(() => DeleteVehicle(sl<VehicleRepository>()));
  sl.registerLazySingleton(() => WatchAllVehicles(sl<VehicleRepository>()));
  sl.registerFactory(
    () => VehicleCubit(
      watchAllVehicles: sl<WatchAllVehicles>(),
      addVehicle: sl<AddVehicle>(),
      updateVehicle: sl<UpdateVehicle>(),
      deleteVehicle: sl<DeleteVehicle>(),
    ),
  );
  sl.registerFactory(
    () => StartupCubit(sl<VehicleRepository>()),
  );

  sl.registerLazySingleton<FuelLocalDataSource>(
    () => FuelHiveDataSource(),
  );
  sl.registerLazySingleton<FuelRepository>(
    () => FuelRepositoryImpl(sl<FuelLocalDataSource>()),
  );
  sl.registerLazySingleton(() => GetFuelEntriesByVehicle(sl<FuelRepository>()));
  sl.registerLazySingleton(() => GetLastFuelEntry(sl<FuelRepository>()));
  sl.registerLazySingleton(() => AddFuelEntry(sl<FuelRepository>()));
  sl.registerLazySingleton(() => UpdateFuelEntry(sl<FuelRepository>()));
  sl.registerLazySingleton(() => DeleteFuelEntry(sl<FuelRepository>()));
  sl.registerLazySingleton(
      () => WatchFuelEntriesByVehicle(sl<FuelRepository>()));
  sl.registerLazySingleton(
      () => GetTotalFuelCostByVehicle(sl<FuelRepository>()));
  sl.registerLazySingleton(
    () => RecalculateFuelConsumption(
      sl<FuelRepository>(),
      sl<VehicleRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => SyncVehicleOdometer(
      sl<FuelRepository>(),
      sl<MaintenanceRepository>(),
      sl<VehicleRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => EditFuelEntry(
      sl<FuelRepository>(),
      sl<RecalculateFuelConsumption>(),
      sl<SyncVehicleOdometer>(),
    ),
  );
  sl.registerLazySingleton(
    () => RemoveFuelEntry(
      sl<FuelRepository>(),
      sl<RecalculateFuelConsumption>(),
      sl<SyncVehicleOdometer>(),
    ),
  );
  sl.registerFactory(
    () => FuelCubit(
      watchFuelEntries: sl<WatchFuelEntriesByVehicle>(),
      addFuelEntry: sl<AddFuelEntry>(),
      editFuelEntry: sl<EditFuelEntry>(),
      removeFuelEntry: sl<RemoveFuelEntry>(),
      getTotalCost: sl<GetTotalFuelCostByVehicle>(),
      recalculateConsumption: sl<RecalculateFuelConsumption>(),
    ),
  );

  sl.registerLazySingleton<MaintenanceLocalDataSource>(
    () => MaintenanceHiveDataSource(),
  );
  sl.registerLazySingleton<MaintenanceRepository>(
    () => MaintenanceRepositoryImpl(sl<MaintenanceLocalDataSource>()),
  );
  sl.registerLazySingleton(
      () => GetMaintenanceByVehicle(sl<MaintenanceRepository>()));
  sl.registerLazySingleton(
      () => GetUpcomingMaintenance(sl<MaintenanceRepository>()));
  sl.registerLazySingleton(() => AddMaintenance(sl<MaintenanceRepository>()));
  sl.registerLazySingleton(
      () => UpdateMaintenance(sl<MaintenanceRepository>()));
  sl.registerLazySingleton(
      () => DeleteMaintenance(sl<MaintenanceRepository>()));
  sl.registerLazySingleton(
      () => WatchMaintenanceByVehicle(sl<MaintenanceRepository>()));
  sl.registerLazySingleton(() => RunMaintenanceReminderChecks(
        sl<VehicleRepository>(),
        sl<MaintenanceRepository>(),
        sl<NotificationService>(),
      ));
  sl.registerFactory(
    () => MaintenanceCubit(
      watchMaintenance: sl<WatchMaintenanceByVehicle>(),
      addMaintenance: sl<AddMaintenance>(),
      deleteMaintenance: sl<DeleteMaintenance>(),
      getUpcoming: sl<GetUpcomingMaintenance>(),
      notificationService: sl<NotificationService>(),
    ),
  );

  sl.registerLazySingleton<PartReplacementLocalDataSource>(
    () => PartReplacementHiveDataSource(),
  );
  sl.registerLazySingleton<PartReplacementRepository>(
    () => PartReplacementRepositoryImpl(sl<PartReplacementLocalDataSource>()),
  );

  sl.registerLazySingleton<RentalLocalDataSource>(
    () => RentalHiveDataSource(),
  );
  sl.registerLazySingleton<RentalRepository>(
    () => RentalRepositoryImpl(sl<RentalLocalDataSource>()),
  );
  sl.registerLazySingleton(() => GetAllRentals(sl<RentalRepository>()));
  sl.registerLazySingleton(() => GetRentalsByVehicle(sl<RentalRepository>()));
  sl.registerLazySingleton(() => AddRental(sl<RentalRepository>()));
  sl.registerLazySingleton(() => UpdateRental(sl<RentalRepository>()));
  sl.registerLazySingleton(() => DeleteRental(sl<RentalRepository>()));
  sl.registerLazySingleton(() => WatchAllRentals(sl<RentalRepository>()));
  sl.registerFactory(
    () => RentalCubit(
      watchAllRentals: sl<WatchAllRentals>(),
      getAllRentals: sl<GetAllRentals>(),
      addRental: sl<AddRental>(),
      updateRental: sl<UpdateRental>(),
      deleteRental: sl<DeleteRental>(),
      getVehicleById: sl<GetVehicleById>(),
      updateVehicle: sl<UpdateVehicle>(),
    ),
  );

  sl.registerFactory(
    () => AnalyticsCubit(
      fuelRepository: sl<FuelRepository>(),
      maintenanceRepository: sl<MaintenanceRepository>(),
      vehicleRepository: sl<VehicleRepository>(),
    ),
  );

  sl.registerSingleton<PerformanceService>(PerformanceService());
  sl.registerLazySingleton<MaintenanceService>(
      () => const MaintenanceService());
  sl.registerLazySingleton<PartsLifecycleService>(
    () => const PartsLifecycleService(),
  );
}
