import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/database/hive_storage.dart';
import '../models/maintenance_entry_model.dart';
import 'maintenance_local_datasource.dart';

class MaintenanceHiveDataSource implements MaintenanceLocalDataSource {
  MaintenanceHiveDataSource() : _box = maintenanceEntriesBox();

  final Box<dynamic> _box;

  List<MaintenanceEntryModel> _byVehicle(String vehicleId) {
    final list = <MaintenanceEntryModel>[];
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) {
        final map = Map<String, dynamic>.from(v);
        if ((map['vehicle_id'] as String?) != vehicleId) continue;
        try {
          list.add(MaintenanceEntryModel.fromMap(map));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return list;
  }

  double _sumCost(Iterable<MaintenanceEntryModel> entries) {
    return entries.fold<double>(0, (s, e) => s + e.cost);
  }

  @override
  Future<List<MaintenanceEntryModel>> getMaintenanceByVehicle(
    String vehicleId,
  ) async =>
      _byVehicle(vehicleId);

  @override
  Future<List<MaintenanceEntryModel>> getUpcomingMaintenance({
    int daysAhead = 7,
  }) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfRange = startOfToday.add(Duration(days: daysAhead));
    final list = <MaintenanceEntryModel>[];
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) {
        try {
          final e =
              MaintenanceEntryModel.fromMap(Map<String, dynamic>.from(v));
          final next = e.nextServiceDate;
          if (next != null) {
            final nextDateOnly = DateTime(next.year, next.month, next.day);
            if (!nextDateOnly.isBefore(startOfToday) &&
                !nextDateOnly.isAfter(endOfRange)) {
              list.add(e);
            }
          }
        } catch (_) {}
      }
    }
    list.sort((a, b) => a.nextServiceDate!.compareTo(b.nextServiceDate!));
    return list;
  }

  @override
  Future<void> saveMaintenance(MaintenanceEntryModel model) async {
    await _box.put(model.id, model.toMap());
  }

  @override
  Future<void> deleteMaintenance(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<MaintenanceEntryModel>> watchMaintenanceByVehicle(
    String vehicleId,
  ) async* {
    yield _byVehicle(vehicleId);
    await for (final _ in _box.watch()) {
      yield _byVehicle(vehicleId);
    }
  }

  @override
  Future<double> getTotalCostByVehicle(String vehicleId) async =>
      _sumCost(_byVehicle(vehicleId));

  @override
  Future<double> getTotalCostInRange(DateTime from, DateTime to) async {
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();
    final list = <MaintenanceEntryModel>[];
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) {
        try {
          final e =
              MaintenanceEntryModel.fromMap(Map<String, dynamic>.from(v));
          final d = e.serviceDate.toIso8601String();
          if (d.compareTo(fromStr) >= 0 && d.compareTo(toStr) <= 0) {
            list.add(e);
          }
        } catch (_) {}
      }
    }
    return _sumCost(list);
  }

  @override
  Future<double> getTotalCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  ) async {
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();
    final list = _byVehicle(vehicleId).where((e) {
      final d = e.serviceDate.toIso8601String();
      return d.compareTo(fromStr) >= 0 && d.compareTo(toStr) <= 0;
    });
    return _sumCost(list);
  }
}
