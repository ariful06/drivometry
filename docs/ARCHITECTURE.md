# Drivometry architecture

## Layer separation

The app follows **Clean Architecture** with three clear layers so the **data layer can be replaced** (e.g. with Hive, Isar, or a remote API) without changing UI or domain.

```
┌─────────────────────────────────────────────────────────┐
│  Presentation (UI)                                      │
│  - Pages, widgets, Cubits                               │
│  - Depends on: Domain (entities, use cases)             │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  Domain                                                  │
│  - Entities (Vehicle, FuelEntry, MaintenanceEntry)      │
│  - Repository interfaces (VehicleRepository, etc.)        │
│  - Use cases (GetAllVehicles, AddFuelEntry, etc.)       │
│  - Depends on: nothing from lib/features/*/data         │
└─────────────────────────────────────────────────────────┘
                            ▲
                            │
┌─────────────────────────────────────────────────────────┐
│  Data                                                    │
│  - Repository implementations (VehicleRepositoryImpl)    │
│  - Data sources (VehicleLocalDataSource + impl)         │
│  - Models (VehicleModel, toMap/fromMap)                 │
│  - Depends on: Domain (entities, repository interfaces) │
└─────────────────────────────────────────────────────────┘
```

### Rules

- **Domain** must not import anything from any feature’s `data/` folder (or from `core/database` implementation details). It may use `core/errors`, `core/constants`, and platform packages where needed (e.g. notifications).
- **Presentation** imports only **domain** (entities, use cases) and **core** (theme, router, widgets). It must not import feature `data/` (no models, no datasources, no repository impls).
- **Data** implements domain repository interfaces and uses its own models and datasources. All persistence (sqflite, Hive, etc.) lives only in the data layer.

Dependency injection (`injection_container.dart`) is the only place that ties concrete data implementations to the app: it registers repository **interfaces** with their **implementations** and datasources.

---

## Swapping the data layer (e.g. to Hive)

To move from sqflite to Hive (or another store) without changing UI or domain:

1. **Keep domain as-is**  
   Repository interfaces and entities stay unchanged.

2. **Add new data implementation**  
   For each feature (e.g. vehicles):
   - Add a new datasource that implements the existing abstract datasource, e.g. `VehicleHiveDataSource implements VehicleLocalDataSource`, using Hive boxes instead of sqflite.
   - Add (or adapt) a model that maps between Hive and domain entities (e.g. `VehicleModel.fromEntity` / `toEntity()`).
   - Keep `VehicleRepositoryImpl` but make it depend on `VehicleLocalDataSource` (the interface). It already does; it doesn’t care whether the implementation is sqflite or Hive.

3. **Register the new implementation in DI**  
   In `injection_container.dart`:
   - Register `VehicleLocalDataSource` with `VehicleHiveDataSource` (and any Hive-specific dependencies) instead of `VehicleLocalDataSourceImpl`.
   - Keep `VehicleRepository` registered with `VehicleRepositoryImpl(sl<VehicleLocalDataSource>())`.

4. **Optional: remove old implementation**  
   Once Hive is working, you can delete the sqflite datasource and `DatabaseHelper` usage for that feature, or keep both and switch via a flag.

No changes are required in presentation or domain; only the data layer and `injection_container.dart` change.

---

## Database migrations (current data layer)

The app uses sqflite. Migrations are handled in `core/database/database_helper.dart`:

- `kDatabaseVersion` is the current schema version.
- `onCreate` runs only for a fresh install.
- `onUpgrade(oldVersion, newVersion)` runs when the app is updated and the stored DB version is lower than `kDatabaseVersion`.

When you add a new table or column:

1. Bump `kDatabaseVersion` (e.g. to 2).
2. In `_onUpgrade`, add a branch, e.g. `if (oldVersion < 2) { ... }`, and run the required `ALTER TABLE` or `CREATE TABLE` statements.

This keeps existing user data intact across updates.
