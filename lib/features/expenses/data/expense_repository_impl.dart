import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/hive_storage.dart';
import '../domain/entities/expense.dart';
import '../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl() : _box = expensesBox();

  final Box<dynamic> _box;

  List<Expense> _read({String? vehicleId}) {
    final list = <Expense>[];
    for (final key in _box.keys) {
      final stored = _box.get(key);
      if (stored is! Map) continue;
      try {
        final expense = Expense.fromMap(Map<String, dynamic>.from(stored));
        if (vehicleId == null || expense.vehicleId == vehicleId) {
          list.add(expense);
        }
      } catch (_) {
        // Skip unreadable rows rather than failing the whole list.
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<Expense>> getByVehicle(String vehicleId) async =>
      _read(vehicleId: vehicleId);

  @override
  Future<List<Expense>> getAll() async => _read();

  @override
  Future<void> add(Expense expense) => _box.put(expense.id, expense.toMap());

  @override
  Future<void> update(Expense expense) => _box.put(expense.id, expense.toMap());

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> deleteByVehicle(String vehicleId) async {
    final ids = _read(vehicleId: vehicleId).map((e) => e.id).toList();
    await _box.deleteAll(ids);
  }
}
