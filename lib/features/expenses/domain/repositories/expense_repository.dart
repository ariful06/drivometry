import '../entities/expense.dart';

abstract class ExpenseRepository {
  /// Newest first.
  Future<List<Expense>> getByVehicle(String vehicleId);
  Future<List<Expense>> getAll();
  Future<void> add(Expense expense);
  Future<void> update(Expense expense);
  Future<void> delete(String id);
  Future<void> deleteByVehicle(String vehicleId);
}
