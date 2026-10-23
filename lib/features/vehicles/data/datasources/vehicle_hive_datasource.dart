import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/database/hive_storage.dart';
import 'vehicle_local_datasource.dart';
import '../models/vehicle_model.dart';

class VehicleHiveDataSource implements VehicleLocalDataSource {
  VehicleHiveDataSource() : _box = vehiclesBox();

  final Box<dynamic> _box;

  List<VehicleModel> _all() {
    final list = <VehicleModel>[];
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) {
        try {
          list.add(VehicleModel.fromMap(Map<String, dynamic>.from(v)));
        } catch (_) {}
      }
    }
    list.sort(
      (leftVehicle, rightVehicle) =>
          leftVehicle.createdAt.compareTo(rightVehicle.createdAt),
    );
    return list;
  }

  @override
  Future<List<VehicleModel>> getAllVehicles() async => _all();

  @override
  Future<VehicleModel?> getVehicleById(String id) async {
    final v = _box.get(id);
    if (v is! Map) return null;
    return VehicleModel.fromMap(Map<String, dynamic>.from(v));
  }

  @override
  Future<void> saveVehicle(VehicleModel model) async {
    await _box.put(model.id, model.toMap());
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _box.delete(id);
    for (final related in [
      fuelEntriesBox(),
      maintenanceEntriesBox(),
      partReplacementsBox(),
      rentalEntriesBox(),
      expensesBox(),
    ]) {
      final keys = related.keys.where((key) {
        final v = related.get(key);
        return v is Map && v['vehicle_id'] == id;
      }).toList();
      await related.deleteAll(keys);
    }
  }

  @override
  Stream<List<VehicleModel>> watchAllVehicles() async* {
    yield _all(); // emit current list as soon as someone listens
    await for (final _ in _box.watch()) {
      yield _all();
    }
  }
}
