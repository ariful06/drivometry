import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/database/hive_storage.dart';
import 'part_replacement_local_datasource.dart';
import '../models/part_replacement_model.dart';

class PartReplacementHiveDataSource
    implements PartReplacementLocalDataSource {
  PartReplacementHiveDataSource() : _box = partReplacementsBox();

  final Box<dynamic> _box;

  List<PartReplacementModel> _byVehicle(String vehicleId) {
    final list = <PartReplacementModel>[];
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) {
        final map = Map<String, dynamic>.from(v);
        if ((map['vehicle_id'] as String?) != vehicleId) continue;
        try {
          list.add(PartReplacementModel.fromMap(map));
        } catch (_) {}
      }
    }
    list.sort(
      (leftReplacement, rightReplacement) => rightReplacement.installOdometer
          .compareTo(leftReplacement.installOdometer),
    );
    return list;
  }

  @override
  Future<List<PartReplacementModel>> getByVehicle(String vehicleId) async =>
      _byVehicle(vehicleId);

  @override
  Future<void> save(PartReplacementModel model) async {
    await _box.put(model.id, model.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<PartReplacementModel>> watchByVehicle(String vehicleId) async* {
    yield _byVehicle(vehicleId);
    await for (final _ in _box.watch()) {
      yield _byVehicle(vehicleId);
    }
  }
}
