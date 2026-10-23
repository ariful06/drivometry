import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/expense.dart';

/// Pops with the new [Expense]; the caller persists it.
class AddExpensePage extends StatefulWidget {
  const AddExpensePage({required this.vehicle, super.key});
  final Vehicle vehicle;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _odometer = TextEditingController();
  final _notes = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.insurance;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _odometer.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.pop(Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      vehicleId: widget.vehicle.id,
      date: _date,
      category: _category,
      amount: double.parse(_amount.text.trim()),
      odometer: double.tryParse(_odometer.text.trim()),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<ExpenseCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in ExpenseCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount *'),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter an amount greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(Formatters.formatDate(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _odometer,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Odometer (km, optional)'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final odo = double.tryParse(value.trim());
                return odo == null || odo < 0 ? 'Enter a valid reading' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save expense')),
          ],
        ),
      ),
    );
  }
}
