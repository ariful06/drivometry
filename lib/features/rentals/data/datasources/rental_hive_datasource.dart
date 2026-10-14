import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/database/hive_storage.dart';
import '../models/rental_entry_model.dart';
import 'rental_local_datasource.dart';

class RentalHiveDataSource implements RentalLocalDataSource {
  RentalHiveDataSource() : _box = rentalEntriesBox();

  final Box<dynamic> _box;

  List<RentalEntryModel> _all() {
    final list = <RentalEntryModel>[];
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) {
        try {
          list.add(RentalEntryModel.fromMap(Map<String, dynamic>.from(v)));
        } catch (_) {}
      }
    }
    list.sort(
      (leftRental, rightRental) =>
          rightRental.bookingDate.compareTo(leftRental.bookingDate),
    );
    return list;
  }

  @override
  Future<List<RentalEntryModel>> getAllRentals() async => _all();

  @override
  Future<List<RentalEntryModel>> getRentalsByVehicle(String vehicleId) async =>
      _all().where((rentalRow) => rentalRow.vehicleId == vehicleId).toList();

  @override
  Future<void> saveRental(RentalEntryModel model) async {
    await _box.put(model.id, model.toMap());
  }

  @override
  Future<void> deleteRental(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<RentalEntryModel>> watchAllRentals() async* {
    yield _all();
    await for (final _ in _box.watch()) {
      yield _all();
    }
  }
}
