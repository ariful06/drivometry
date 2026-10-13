import 'package:drivometry/features/fuel/domain/entities/fuel_entry.dart';
import 'package:drivometry/features/fuel/domain/services/fuel_consumption_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

FuelEntry _fill(
  String id,
  double odometer,
  double liters, {
  bool full = true,
  bool missed = false,
  double? level,
  DateTime? date,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v',
      date: date ?? DateTime(2026, 1, 1).add(Duration(days: odometer ~/ 100)),
      odometer: odometer,
      liters: liters,
      costPerLiter: 1,
      totalCost: liters,
      isFullTank: full,
      missedPreviousFill: missed,
      fuelLevelPercent: level,
    );

void main() {
  test('full-to-full: (odo - prev odo) / current liters', () {
    final segment = FuelConsumptionCalculator.segmentsByEntryId([
      _fill('a', 10000, 50),
      _fill('b', 10300, 20),
    ])['b']!;
    expect(segment.kmPerLiter, 15);
    expect(segment.isEstimated, isFalse);
  });

  test('first full tank only opens a period; its liters are ignored', () {
    final segments = FuelConsumptionCalculator.segmentsByEntryId([
      _fill('a', 1000, 40),
      _fill('b', 1500, 25),
    ]);
    expect(segments.keys, ['b']);
    expect(segments['b']!.kmPerLiter, 20);
  });

  test('partial fills roll into the next full tank', () {
    final segments = FuelConsumptionCalculator.segmentsByEntryId([
      _fill('a', 1000, 40),
      _fill('p1', 1200, 10, full: false),
      _fill('p2', 1400, 10, full: false),
      _fill('b', 1600, 10),
    ]);
    expect(segments.keys, ['b']);
    expect(segments['b']!.distanceKm, 600);
    expect(segments['b']!.liters, 30);
    expect(segments['b']!.fillCount, 3);
  });

  test('partial fills before the first full tank are ignored', () {
    final segments = FuelConsumptionCalculator.segmentsByEntryId([
      _fill('p', 900, 15, full: false),
      _fill('a', 1000, 40),
      _fill('b', 1300, 20),
    ]);
    expect(segments['b']!.kmPerLiter, 15);
    expect(segments.length, 1);
  });

  test('missed fill-up breaks the chain and restarts at a full tank', () {
    final segments = FuelConsumptionCalculator.segmentsByEntryId([
      _fill('a', 1000, 40),
      _fill('b', 1800, 20, missed: true),
      _fill('c', 2200, 20),
    ]);
    expect(segments.keys, ['c']);
    expect(segments['c']!.kmPerLiter, 20);
  });

  test('average is total km over total liters, input order irrelevant', () {
    final average = FuelConsumptionCalculator.averageKmPerLiter([
      _fill('c', 1900, 30),
      _fill('a', 1000, 40),
      _fill('b', 1300, 30),
    ]);
    expect(average, 900 / 60);
  });

  test('preview only for a full-tank draft', () {
    final history = [_fill('a', 1000, 40), _fill('p', 1200, 10, full: false)];
    expect(
      FuelConsumptionCalculator.previewForDraft(
        history,
        _fill('d', 1500, 20),
      )!.kmPerLiter,
      500 / 30,
    );
    expect(
      FuelConsumptionCalculator.previewForDraft(
        history,
        _fill('d', 1500, 20, full: false),
      ),
      isNull,
    );
  });

  test('odometer reset breaks the chain instead of reordering history', () {
    final segments = FuelConsumptionCalculator.segments([
      _fill('a', 79500, 40, date: DateTime(2026, 1, 1)),
      _fill('b', 80000, 25, date: DateTime(2026, 1, 10)),
      // cluster replaced → reading restarts
      _fill('c', 200, 30, date: DateTime(2026, 1, 20)),
      _fill('d', 500, 20, date: DateTime(2026, 1, 30)),
    ]);
    expect(segments.map((s) => s.endEntryId), ['b', 'd']);
    expect(segments.last.kmPerLiter, 15);
  });

  test('closing fill with non-increasing odometer is not measured', () {
    final segments = FuelConsumptionCalculator.segmentsByEntryId([
      _fill('a', 1000, 40, date: DateTime(2026, 1, 1)),
      _fill('p', 1200, 15, full: false, date: DateTime(2026, 1, 2)),
      _fill('typo', 1200, 25, date: DateTime(2026, 1, 3)),
      _fill('b', 1500, 20, date: DateTime(2026, 1, 4)),
    ]);
    expect(segments.containsKey('typo'), isFalse);
    expect(segments['b']!.kmPerLiter, 15);
  });

  group('tank capacity estimate (no full-tank baseline)', () {
    test('consecutive partials with gauge levels', () {
      // 50 L tank: 60 % after first fill (30 L), drive 300 km,
      // add 20 L and gauge reads 80 % (40 L) → used 30 + 20 - 40 = 10 L
      final segment = FuelConsumptionCalculator.segmentsByEntryId(
        [
          _fill('p1', 1000, 25, full: false, level: 60),
          _fill('p2', 1300, 20, full: false, level: 80),
        ],
        tankCapacityLiters: 50,
      )['p2']!;
      expect(segment.isEstimated, isTrue);
      expect(segment.liters, closeTo(10, 1e-9));
      expect(segment.kmPerLiter, closeTo(30, 1e-9));
    });

    test('partial with level followed by first full tank', () {
      // 40 % (20 L) after partial, drive 200 km, 40 L to fill → used 10 L
      final segment = FuelConsumptionCalculator.segmentsByEntryId(
        [
          _fill('p1', 1000, 10, full: false, level: 40),
          _fill('f', 1200, 40),
        ],
        tankCapacityLiters: 50,
      )['f']!;
      expect(segment.isEstimated, isTrue);
      expect(segment.kmPerLiter, closeTo(20, 1e-9));
    });

    test('needs tank capacity and both gauge levels', () {
      expect(
        FuelConsumptionCalculator.segments(
          [
            _fill('p1', 1000, 25, full: false, level: 60),
            _fill('p2', 1300, 20, full: false),
          ],
          tankCapacityLiters: 50,
        ),
        isEmpty,
      );
      expect(
        FuelConsumptionCalculator.segments([
          _fill('p1', 1000, 25, full: false, level: 60),
          _fill('p2', 1300, 20, full: false, level: 80),
        ]),
        isEmpty,
      );
    });

    test('exact full-to-full wins once a baseline exists', () {
      final segments = FuelConsumptionCalculator.segmentsByEntryId(
        [
          _fill('a', 1000, 40),
          _fill('p', 1200, 10, full: false, level: 70),
          _fill('b', 1500, 20),
        ],
        tankCapacityLiters: 50,
      );
      expect(segments.keys, ['b']);
      expect(segments['b']!.isEstimated, isFalse);
      expect(segments['b']!.liters, 30);
    });
  });
}
