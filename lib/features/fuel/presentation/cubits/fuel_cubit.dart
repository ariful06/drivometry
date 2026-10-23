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
    required EditFuelEntry editFuelEntry,
    required RemoveFuelEntry removeFuelEntry,
    required GetTotalFuelCostByVehicle getTotalCost,
    required RecalculateFuelConsumption recalculateConsumption,
  })  : _watchFuelEntries = watchFuelEntries,
        _addFuelEntry = addFuelEntry,
        _editFuelEntry = editFuelEntry,
        _removeFuelEntry = removeFuelEntry,
        _getTotalCost = getTotalCost,
        _recalculateConsumption = recalculateConsumption,
        super(const FuelInitial());

  final WatchFuelEntriesByVehicle _watchFuelEntries;
  final AddFuelEntry _addFuelEntry;
  final EditFuelEntry _editFuelEntry;
  final RemoveFuelEntry _removeFuelEntry;
  final GetTotalFuelCostByVehicle _getTotalCost;
  final RecalculateFuelConsumption _recalculateConsumption;
  StreamSubscription<List<FuelEntry>>? _subscription;

  void watchForVehicle(String vehicleId) {
    emit(const FuelLoading());
    _subscription?.cancel();
    _subscription = _watchFuelEntries(vehicleId).listen(
      (entries) async {
        final total = await _getTotalCost(vehicleId);
        emit(FuelLoaded(entries: entries, totalCost: total));
      },
      onError: (Object error) => emit(FuelError(error.toString())),
    );
  }

  Future<void> addFuelEntry({
    required String vehicleId,
    required DateTime date,
    required double odometer,
    required double liters,
    required double costPerLiter,
    required double prevOdometer,
    bool isFullTank = true,
    String? notes,
  }) async {
    try {
      final distance = odometer > prevOdometer ? odometer - prevOdometer : null;
      final entry = FuelEntry(
        id: const Uuid().v4(),
        vehicleId: vehicleId,
        date: date,
        odometer: odometer,
        liters: liters,
        costPerLiter: costPerLiter,
        totalCost: liters * costPerLiter,
        notes: notes,
        distanceDriven: distance,
        isFullTank: isFullTank,
      );
      await _addFuelEntry(entry);
      await _recalculateConsumption(vehicleId);
    } catch (error) {
      emit(FuelError(error.toString()));
    }
  }

  /// Saves an edited fill; consumption and vehicle odometer are recalculated.
  Future<void> updateFuelEntry(FuelEntry entry) async {
    try {
      await _editFuelEntry(entry);
    } catch (error) {
      emit(FuelError(error.toString()));
    }
  }

  /// Deletes a fill; consumption and vehicle odometer are recalculated.
  Future<void> deleteFuelEntry(FuelEntry entry) async {
    try {
      await _removeFuelEntry(entry);
    } catch (error) {
      emit(FuelError(error.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
