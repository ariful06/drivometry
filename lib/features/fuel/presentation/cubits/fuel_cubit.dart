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
    required RecalculateFuelConsumption recalculateConsumption,
  })  : _watchFuelEntries = watchFuelEntries,
        _addFuelEntry = addFuelEntry,
        _updateFuelEntry = updateFuelEntry,
        _deleteFuelEntry = deleteFuelEntry,
        _getTotalCost = getTotalCost,
        _recalculateConsumption = recalculateConsumption,
        super(const FuelInitial());

  final WatchFuelEntriesByVehicle _watchFuelEntries;
  final AddFuelEntry _addFuelEntry;
  final UpdateFuelEntry _updateFuelEntry;
  final DeleteFuelEntry _deleteFuelEntry;
  final GetTotalFuelCostByVehicle _getTotalCost;
  final RecalculateFuelConsumption _recalculateConsumption;
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

  Future<void> updateFuelEntry(FuelEntry entry) async {
    try {
      await _updateFuelEntry(entry);
      await _recalculateConsumption(entry.vehicleId);
    } catch (error) {
      emit(FuelError(error.toString()));
    }
  }

  Future<void> deleteFuelEntry(String id, {String? vehicleId}) async {
    try {
      await _deleteFuelEntry(id);
      final affectedVehicleId = vehicleId ?? _currentVehicleId;
      if (affectedVehicleId != null) {
        await _recalculateConsumption(affectedVehicleId);
      }
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
