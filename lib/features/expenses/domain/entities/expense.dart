// lib/features/expenses/domain/entities/expense.dart

/// Money spent on a vehicle that is not a fuel fill or a maintenance invoice.
/// (Fuel and maintenance have their own records; the expense ledger combines
/// them — see docs/EXPENSE_RULES.md once T23 lands.)
enum ExpenseCategory {
  insurance('Insurance'),
  registration('Registration'),
  tax('Tax'),
  parking('Parking'),
  toll('Toll'),
  wash('Wash'),
  repair('Repair'),
  misc('Other');

  const ExpenseCategory(this.label);
  final String label;

  static ExpenseCategory fromName(String? name) => ExpenseCategory.values
      .firstWhere((c) => c.name == name, orElse: () => ExpenseCategory.misc);
}

class Expense {
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.amount,
    this.odometer,
    this.notes,
    this.receiptImagePath,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final ExpenseCategory category;
  final double amount;
  final double? odometer;
  final String? notes;
  final String? receiptImagePath;

  Expense copyWith({
    DateTime? date,
    ExpenseCategory? category,
    double? amount,
    double? odometer,
    String? notes,
    String? receiptImagePath,
  }) =>
      Expense(
        id: id,
        vehicleId: vehicleId,
        date: date ?? this.date,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        odometer: odometer ?? this.odometer,
        notes: notes ?? this.notes,
        receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'date': date.toIso8601String(),
        'category': category.name,
        'amount': amount,
        'odometer': odometer,
        'notes': notes,
        'receipt_image_path': receiptImagePath,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        vehicleId: map['vehicle_id'] as String,
        date: DateTime.parse(map['date'] as String),
        category: ExpenseCategory.fromName(map['category'] as String?),
        amount: (map['amount'] as num).toDouble(),
        odometer: (map['odometer'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
        receiptImagePath: map['receipt_image_path'] as String?,
      );
}
