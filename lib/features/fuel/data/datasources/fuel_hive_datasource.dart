import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/database/hive_storage.dart';
import 'fuel_local_datasource.dart';
import '../models/fuel_entry_model.dart';

class FuelHiveDataSource implements FuelLocalDataSource {
  FuelHiveDataSource() : _box = fuelEntriesBox();

  final Box<dynamic> _box;

  List<FuelEntryModel> _byVehicle(String vehicleId) {
    final list = <FuelEntryModel>[];
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) {
        final map = Map<String, dynamic>.from(v);
        if ((map['vehicle_id'] as String?) != vehicleId) continue;
        try {
          list.add(FuelEntryModel.fromMap(map));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double _sumTotalCost(Iterable<FuelEntryModel> entries) {
    return entries.fold<double>(0, (s, e) => s + e.totalCost);
  }

  @override
  Future<List<FuelEntryModel>> getFuelEntriesByVehicle(String vehicleId) async =>
      _byVehicle(vehicleId);

  @override
  Future<FuelEntryModel?> getLastFuelEntry(String vehicleId) async {
    final list = _byVehicle(vehicleId);
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<void> saveFuelEntry(FuelEntryModel model) async {
    await _box.put(model.id, model.toMap());
  }

  @override
  Future<void> deleteFuelEntry(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<FuelEntryModel>> watchFuelEntriesByVehicle(String vehicleId) async* {
    yield _byVehicle(vehicleId);
    await for (final _ in _box.watch()) {
      yield _byVehicle(vehicleId);
    }
  }

  @override
  Future<double> getTotalFuelCostByVehicle(String vehicleId) async =>
      _sumTotalCost(_byVehicle(vehicleId));

  @override
  Future<double> getTotalFuelCostInRange(DateTime from, DateTime to) async {
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();
    final list = <FuelEntryModel>[];
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) {
        try {
          final e = FuelEntryModel.fromMap(Map<String, dynamic>.from(v));
          final d = e.date.toIso8601String();
          if (d.compareTo(fromStr) >= 0 && d.compareTo(toStr) <= 0) {
            list.add(e);
          }
        } catch (_) {}
      }
    }
    return _sumTotalCost(list);
  }

  @override
  Future<double> getTotalFuelCostByVehicleInRange(
    String vehicleId,
    DateTime from,
    DateTime to,
  ) async {
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();
    final list = _byVehicle(vehicleId).where((e) {
      final d = e.date.toIso8601String();
      return d.compareTo(fromStr) >= 0 && d.compareTo(toStr) <= 0;
    });
    return _sumTotalCost(list);
  }
}
