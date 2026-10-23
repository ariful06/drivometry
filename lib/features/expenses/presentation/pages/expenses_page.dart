import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/expense.dart';
import '../cubits/expense_cubit.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({required this.vehicle, super.key});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExpenseCubit>(param1: vehicle.id)..load(),
      child: _ExpensesView(vehicle: vehicle),
    );
  }
}

class _ExpensesView extends StatelessWidget {
  const _ExpensesView({required this.vehicle});
  final Vehicle vehicle;

  Future<void> _add(BuildContext context) async {
    final expense = await context
        .push<Expense>('/vehicles/${vehicle.id}/expenses/add', extra: vehicle);
    if (expense != null && context.mounted) {
      await context.read<ExpenseCubit>().add(expense);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: Text('${vehicle.name} · Expenses')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add expense',
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) => switch (state) {
          ExpenseLoading() => const LoadingOverlay(),
          ExpenseError(:final message) =>
            Center(child: Text('Error: $message')),
          ExpenseLoaded(:final expenses) when expenses.isEmpty =>
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              subtitle: 'Track insurance, tax, parking, tolls and more.',
            ),
          ExpenseLoaded() => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                StatCard(
                  label: 'Total other expenses',
                  value: Formatters.formatCurrency(state.total),
                  icon: Icons.receipt_long_outlined,
                  color: colors.partsColor,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in state.totalsByCategory.entries)
                      Chip(
                        label: Text(
                          '${entry.key.label}: '
                          '${Formatters.formatCurrency(entry.value)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final expense in state.expenses)
                  Dismissible(
                    key: ValueKey(expense.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) =>
                        context.read<ExpenseCubit>().delete(expense.id),
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(expense.category.label),
                      subtitle: Text([
                        Formatters.formatDate(expense.date),
                        if (expense.notes?.isNotEmpty ?? false) expense.notes!,
                      ].join(' · ')),
                      trailing: Text(
                        Formatters.formatCurrency(expense.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
        },
      ),
    );
  }
}
