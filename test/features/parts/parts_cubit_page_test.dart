import 'package:drivometry/core/theme/app_theme.dart';
import 'package:drivometry/features/parts/domain/entities/part_replacement.dart';
import 'package:drivometry/features/parts/domain/repositories/part_replacement_repository.dart';
import 'package:drivometry/features/parts/domain/services/parts_lifecycle_service.dart';
import 'package:drivometry/features/parts/presentation/cubits/parts_cubit.dart';
import 'package:drivometry/features/parts/presentation/pages/parts_page.dart';
import 'package:drivometry/features/vehicles/domain/entities/vehicle.dart';
import 'package:drivometry/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryParts implements PartReplacementRepository {
  final rows = <String, PartReplacement>{};

  @override
  Future<void> add(PartReplacement part) async => rows[part.id] = part;

  @override
  Future<void> update(PartReplacement part) async => rows[part.id] = part;

  @override
  Future<void> delete(String id) async => rows.remove(id);

  @override
  Future<List<PartReplacement>> getByVehicle(String vehicleId) async =>
      rows.values.where((p) => p.vehicleId == vehicleId).toList();

  @override
  Stream<List<PartReplacement>> watchByVehicle(String vehicleId) =>
      Stream.value(rows.values.where((p) => p.vehicleId == vehicleId).toList());
}

PartReplacement _part(String id, String name,
        {double? km, double odo = 1000, double? cost, String vehicle = 'v'}) =>
    PartReplacement(
      id: id,
      vehicleId: vehicle,
      partName: name,
      installOdometer: odo,
      expectedLifespanKm: km,
      installedAt: DateTime(2026, 1, 1),
      cost: cost,
    );

final _vehicle = Vehicle(
  id: 'v',
  name: 'Car',
  type: 'car',
  make: 'T',
  model: 'M',
  year: 2020,
  licensePlate: 'P',
  initialOdometer: 0,
  currentOdometer: 5000,
  createdAt: DateTime(2024),
);

void main() {
  test('replace keeps the old part as history linked to the new one', () async {
    final repo = _MemoryParts();
    final cubit = PartsCubit(repo, 'v');
    await cubit.add(_part('old', 'Brake pads', km: 20000, cost: 3000));
    await cubit.add(_part('other', 'Wiper blades', vehicle: 'x'));
    final old = (cubit.state as PartsLoaded).parts.single;

    await cubit.replace(
      old,
      _part('new', 'Brake pads', km: 25000, odo: 5000, cost: 3500),
    );

    final state = cubit.state as PartsLoaded;
    expect(state.parts.length, 2);
    expect(state.active.single.id, 'new');
    final history = state.history.single;
    expect(history.id, 'old');
    expect(history.replacedById, 'new');
    expect(history.isReplaced, isTrue);
    expect(state.totalSpent, 6500); // both purchases were real spend
  });

  testWidgets('parts page shows overdue and ok parts and history',
      (tester) async {
    final repo = _MemoryParts();
    await repo.add(_part('a', 'Tyres', km: 3000)); // 1000+3000=4000 < 5000
    await repo.add(_part('b', 'Battery', km: 50000));
    await repo.add(_part('c', 'Old clutch', km: 100)
        .copyWith(replacedAt: DateTime(2026, 6, 1), replacedById: 'b'));
    await sl.reset();
    sl.registerSingleton<PartReplacementRepository>(repo);
    sl.registerSingleton<PartsLifecycleService>(const PartsLifecycleService());
    sl.registerFactoryParam<PartsCubit, String, void>(
        (id, _) => PartsCubit(sl<PartReplacementRepository>(), id));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: PartsPage(vehicle: _vehicle),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tyres'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    // Overdue sorts before OK.
    expect(tester.getTopLeft(find.text('Tyres')).dy,
        lessThan(tester.getTopLeft(find.text('Battery')).dy));
    await tester.scrollUntilVisible(find.text('Old clutch'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Replacement history'), findsOneWidget);
    await sl.reset();
  });
}
