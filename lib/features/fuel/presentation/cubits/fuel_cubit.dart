import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/fuel_entry.dart';
import '../../domain/usecases/fuel_usecases.dart';

part 'fuel_state.dart';

class FuelCubit extends Cubit<FuelState> {
  FuelCubit({
    required WatchFuelEntriesByVehicle watchFuelEntries,
    required AddFuelEntry addFuelEntry,
    required UpdateFuelEntry updateFuelEntry,
    required DeleteFuelEntry deleteFuelEntry,
    required GetTotalFuelCostByVehicle getTotalCost,
  })  : _watchFuelEntries = watchFuelEntries,
        _addFuelEntry = addFuelEntry,
        _updateFuelEntry = updateFuelEntry,
        _deleteFuelEntry = deleteFuelEntry,
        _getTotalCost = getTotalCost,
        super(const FuelInitial());

  final WatchFuelEntriesByVehicle _watchFuelEntries;
  final AddFuelEntry _addFuelEntry;
  final UpdateFuelEntry _updateFuelEntry;
  final DeleteFuelEntry _deleteFuelEntry;
  final GetTotalFuelCostByVehicle _getTotalCost;
  StreamSubscription<List<FuelEntry>>? _subscription;
  String? _currentVehicleId;

  void watchForVehicle(String vehicleId) {
    _currentVehicleId = vehicleId;
    emit(const FuelLoading());
    _subscription?.cancel();
    _subscription = _watchFuelEntries(vehicleId).listen(
          (entries) async {
        final total = await _getTotalCost(vehicleId);
        emit(FuelLoaded(entries: entries, totalCost: total));
      },
      onError: (Object e) => emit(FuelError(e.toString())),
    );
  }

  Future<void> addFuelEntry({
    required String vehicleId,
    required DateTime date,
    required double odometer,
    required double liters,
    required double costPerLiter,
    required double prevOdometer,
    String? notes,
  }) async {
    try {
      final distance = odometer > prevOdometer ? odometer - prevOdometer : null;
      final efficiency = (distance != null && liters > 0) ? distance / liters : null;
      final entry = FuelEntry(
        id: const Uuid().v4(),
        vehicleId: vehicleId,
        date: date,
        odometer: odometer,
        liters: liters,
        costPerLiter: costPerLiter,
        totalCost: liters * costPerLiter,
        notes: notes,
        fuelEfficiency: efficiency,
        distanceDriven: distance,
      );
      await _addFuelEntry(entry);
    } catch (e) {
      emit(FuelError(e.toString()));
    }
  }

  Future<void> updateFuelEntry(FuelEntry entry) async {
    try {
      await _updateFuelEntry(entry);
    } catch (e) {
      emit(FuelError(e.toString()));
    }
  }

  Future<void> deleteFuelEntry(String id) async {
    try {
      await _deleteFuelEntry(id);
    } catch (e) {
      emit(FuelError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}