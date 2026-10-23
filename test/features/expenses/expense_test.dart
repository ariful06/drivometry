import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/features/expenses/domain/entities/expense.dart';
import 'package:drivometry/features/expenses/domain/repositories/expense_repository.dart';
import 'package:drivometry/features/expenses/presentation/cubits/expense_cubit.dart';
import 'package:drivometry/features/expenses/presentation/pages/add_expense_page.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRepo implements ExpenseRepository {
  final rows = <String, Expense>{};

  @override
  Future<void> add(Expense expense) async => rows[expense.id] = expense;

  @override
  Future<void> update(Expense expense) async => rows[expense.id] = expense;

  @override
  Future<void> delete(String id) async => rows.remove(id);

  @override
  Future<void> deleteByVehicle(String vehicleId) async =>
      rows.removeWhere((_, e) => e.vehicleId == vehicleId);

  @override
  Future<List<Expense>> getAll() async => rows.values.toList();

  @override
  Future<List<Expense>> getByVehicle(String vehicleId) async =>
      rows.values.where((e) => e.vehicleId == vehicleId).toList();
}

Expense _expense(String id, ExpenseCategory c, double amount,
        {String vehicleId = 'v'}) =>
    Expense(
      id: id,
      vehicleId: vehicleId,
      date: DateTime(2026, 5, 1),
      category: c,
      amount: amount,
    );

void main() {
  test('expense map round trip keeps every field', () {
    final e = Expense(
      id: '1',
      vehicleId: 'v',
      date: DateTime(2026, 3, 4),
      category: ExpenseCategory.toll,
      amount: 250.5,
      odometer: 1234,
      notes: 'bridge',
      receiptImagePath: '/r.png',
    );
    final back = Expense.fromMap(e.toMap());
    expect(back.category, ExpenseCategory.toll);
    expect(back.amount, 250.5);
    expect(back.odometer, 1234);
    expect(back.notes, 'bridge');
    expect(back.receiptImagePath, '/r.png');
    expect(back.date, DateTime(2026, 3, 4));
  });

  test('unknown category falls back to misc', () {
    expect(ExpenseCategory.fromName('nope'), ExpenseCategory.misc);
    expect(ExpenseCategory.fromName(null), ExpenseCategory.misc);
  });

  test('cubit add/delete is scoped per vehicle and totals by category',
      () async {
    final repo = _MemoryRepo();
    await repo.add(_expense('other', ExpenseCategory.tax, 999, vehicleId: 'x'));
    final cubit = ExpenseCubit(repo, 'v');
    await cubit.add(_expense('a', ExpenseCategory.insurance, 1000));
    await cubit.add(_expense('b', ExpenseCategory.insurance, 500));
    await cubit.add(_expense('c', ExpenseCategory.parking, 50));
    var state = cubit.state as ExpenseLoaded;
    expect(state.expenses.length, 3);
    expect(state.total, 1550);
    expect(state.totalsByCategory[ExpenseCategory.insurance], 1500);
    await cubit.delete('b');
    state = cubit.state as ExpenseLoaded;
    expect(state.total, 1050);
  });

  testWidgets('add page validates amount and returns the expense',
      (tester) async {
    final vehicle = Vehicle(
      id: 'v',
      name: 'Car',
      type: 'car',
      make: 'T',
      model: 'M',
      year: 2020,
      licensePlate: 'P',
      initialOdometer: 0,
      currentOdometer: 0,
      createdAt: DateTime(2024),
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: AddExpensePage(vehicle: vehicle),
    ));
    await tester.tap(find.text('Save expense'));
    await tester.pump();
    expect(find.text('Enter an amount greater than 0'), findsOneWidget);
  });
}
