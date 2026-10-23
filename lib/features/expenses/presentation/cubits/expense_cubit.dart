import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

sealed class ExpenseState {
  const ExpenseState();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  const ExpenseLoaded(this.expenses);
  final List<Expense> expenses;

  double get total => expenses.fold<double>(0, (sum, e) => sum + e.amount);

  Map<ExpenseCategory, double> get totalsByCategory {
    final totals = <ExpenseCategory, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }
}

class ExpenseError extends ExpenseState {
  const ExpenseError(this.message);
  final String message;
}

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit(this._repository, this.vehicleId)
      : super(const ExpenseLoading());

  final ExpenseRepository _repository;
  final String vehicleId;

  Future<void> load() async {
    try {
      emit(ExpenseLoaded(await _repository.getByVehicle(vehicleId)));
    } catch (error) {
      emit(ExpenseError(error.toString()));
    }
  }

  Future<void> add(Expense expense) async {
    await _repository.add(expense);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }
}
