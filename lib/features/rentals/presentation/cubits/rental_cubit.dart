import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/rental_entry.dart';
import '../../domain/usecases/rental_usecases.dart';

part 'rental_state.dart';

class RentalCubit extends Cubit<RentalState> {
  RentalCubit({
    required WatchAllRentals watchAllRentals,
    required AddRental addRental,
    required UpdateRental updateRental,
    required DeleteRental deleteRental,
  })  : _watchAllRentals = watchAllRentals,
        _addRental = addRental,
        _updateRental = updateRental,
        _deleteRental = deleteRental,
        super(const RentalInitial());

  final WatchAllRentals _watchAllRentals;
  final AddRental _addRental;
  final UpdateRental _updateRental;
  final DeleteRental _deleteRental;
  StreamSubscription<List<RentalEntry>>? _subscription;

  void watchAll() {
    emit(const RentalLoading());
    _subscription?.cancel();
    _subscription = _watchAllRentals().listen(
      (entries) {
        final totalFare = entries.fold<double>(0, (sum, e) => sum + e.rentFareAmount);
        final totalDue = entries.fold<double>(0, (sum, e) => sum + e.dueAmount);
        emit(
          RentalLoaded(
            entries: entries,
            totalFare: totalFare,
            totalDue: totalDue,
          ),
        );
      },
      onError: (Object e) => emit(RentalError(e.toString())),
    );
  }

  Future<void> addRental({
    required String vehicleId,
    required String bookingId,
    required DateTime bookingDate,
    required String customerName,
    required String phone,
    required String fromLocation,
    required String toLocation,
    required String tripType,
    required String tripLeg,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required double startKm,
    required double endKm,
    required double rentFareAmount,
    required double advanceReceived,
    required String paymentStatus,
    required String fuelProvidedBy,
    required String driverMode,
    required double fuelCost,
    required bool customerPaidFuelBill,
    String? driverName,
    String? notes,
  }) async {
    try {
      final totalKm = endKm - startKm;
      final dueAmount = RentalEntry.computeDue(
        rentFareAmount: rentFareAmount,
        advanceReceived: advanceReceived,
        fuelCost: fuelCost,
        customerPaidFuelBill: customerPaidFuelBill,
      );
      final entry = RentalEntry(
        id: const Uuid().v4(),
        vehicleId: vehicleId,
        bookingId: bookingId,
        bookingDate: bookingDate,
        customerName: customerName,
        phone: phone,
        fromLocation: fromLocation,
        toLocation: toLocation,
        tripType: tripType,
        tripLeg: tripLeg,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        startKm: startKm,
        endKm: endKm,
        totalKm: totalKm,
        rentFareAmount: rentFareAmount,
        advanceReceived: advanceReceived,
        dueAmount: dueAmount,
        paymentStatus: paymentStatus,
        fuelProvidedBy: fuelProvidedBy,
        driverMode: driverMode,
        driverName: driverName,
        fuelCost: fuelCost,
        customerPaidFuelBill: customerPaidFuelBill,
        notes: notes,
      );
      await _addRental(entry);
    } catch (e) {
      emit(RentalError(e.toString()));
    }
  }

  Future<void> updateRental(RentalEntry entry) async {
    try {
      await _updateRental(entry);
    } catch (e) {
      emit(RentalError(e.toString()));
    }
  }

  Future<void> deleteRental(String id) async {
    try {
      await _deleteRental(id);
    } catch (e) {
      emit(RentalError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
