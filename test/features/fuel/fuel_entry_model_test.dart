import 'package:drivometry/features/fuel/data/models/fuel_entry_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({Map<String, dynamic> extra = const {}}) => {
      'id': 'e1',
      'vehicle_id': 'v1',
      'date': '2026-01-01T00:00:00.000',
      'odometer': 1000,
      'liters': 30,
      'cost_per_liter': 100,
      'total_cost': 3000,
      'is_full_tank': 0,
      ...extra,
    };

void main() {
  test('legacy rows (before full/partial tracking) read as full tanks', () {
    expect(FuelEntryModel.fromMap(_row()).isFullTank, isTrue);
  });

  test('new rows keep their full/partial flag and fuel level', () {
    final model = FuelEntryModel.fromMap(
      _row(extra: {'missed_previous_fill': 0, 'fuel_level_percent': 75}),
    );
    expect(model.isFullTank, isFalse);
    expect(model.fuelLevelPercent, 75);

    final roundTrip = FuelEntryModel.fromMap(model.toMap());
    expect(roundTrip.isFullTank, isFalse);
    expect(roundTrip.fuelLevelPercent, 75);
  });
}
