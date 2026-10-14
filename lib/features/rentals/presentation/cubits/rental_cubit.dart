import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../vehicles/domain/usecases/vehicle_usecases.dart';
import '../../domain/entities/rental_entry.dart';
import '../../domain/usecases/rental_usecases.dart';

part 'rental_state.dart';

class RentalCubit extends Cubit<RentalState> {
  RentalCubit({
    required WatchAllRentals watchAllRentals,
    required GetAllRentals getAllRentals,
    required AddRental addRental,
    required UpdateRental updateRental,
    required DeleteRental deleteRental,
    required GetVehicleById getVehicleById,
    required UpdateVehicle updateVehicle,
  })  : _watchAllRentals = watchAllRentals,
        _getAllRentals = getAllRentals,
        _addRental = addRental,
        _updateRental = updateRental,
        _deleteRental = deleteRental,
        _getVehicleById = getVehicleById,
        _updateVehicle = updateVehicle,
        super(const RentalInitial());

  final WatchAllRentals _watchAllRentals;
  final GetAllRentals _getAllRentals;
  final AddRental _addRental;
  final UpdateRental _updateRental;
  final DeleteRental _deleteRental;
  final GetVehicleById _getVehicleById;
  final UpdateVehicle _updateVehicle;
  StreamSubscription<List<RentalEntry>>? _subscription;

  void watchAll() {
    emit(const RentalLoading());
    _subscription?.cancel();
    _subscription = _watchAllRentals().listen(
      (entries) {
        final totalFare =
            entries.fold<double>(0, (sum, e) => sum + e.rentFareAmount);
        final totalDue = entries.fold<double>(0, (sum, e) => sum + e.dueAmount);
        emit(
          RentalLoaded(
            entries: entries,
            totalFare: totalFare,
            totalDue: totalDue,
          ),
        );
      },
      onError: (Object error) => emit(RentalError(error.toString())),
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
      await _applyTripDistanceDeltaToVehicleOdometer(
        vehicleId: vehicleId,
        deltaTripKm: totalKm,
      );
    } catch (error) {
      emit(RentalError(error.toString()));
    }
  }

  /// Adds [deltaTripKm] to the vehicle dashboard odometer (trip distance), not absolute end KM.
  Future<void> _applyTripDistanceDeltaToVehicleOdometer({
    required String vehicleId,
    required double deltaTripKm,
  }) async {
    if (deltaTripKm == 0) return;
    final vehicle = await _getVehicleById(vehicleId);
    if (vehicle == null) return;
    final updatedReading = vehicle.currentOdometer + deltaTripKm;
    final clampedReading = updatedReading < vehicle.initialOdometer
        ? vehicle.initialOdometer
        : updatedReading;
    await _updateVehicle(
      vehicle.copyWith(currentOdometer: clampedReading),
    );
  }

  Future<RentalEntry?> _rentalWithId(String id) async {
    final rentals = await _getAllRentals();
    for (final rental in rentals) {
      if (rental.id == id) return rental;
    }
    return null;
  }

  Future<void> updateRental(RentalEntry entry) async {
    try {
      final previous = await _rentalWithId(entry.id);
      final previousTotalKm = previous?.totalKm ?? 0;
      await _updateRental(entry);
      await _applyTripDistanceDeltaToVehicleOdometer(
        vehicleId: entry.vehicleId,
        deltaTripKm: entry.totalKm - previousTotalKm,
      );
    } catch (error) {
      emit(RentalError(error.toString()));
    }
  }

  /// Updates fare, trip distance (end odometer from distance), payment choice
  /// (Paid / Partial / Due), optional partial payment amount, and trip completion.
  ///
  /// [paymentStatusSelection]: `Paid` sets advance to billable (fully settled),
  /// `Partial` adds [partialPaymentAmount] to advance, `Due` leaves advance unchanged.
  Future<void> updateRentalFareDistanceAndPayment({
    required RentalEntry entry,
    required double rentFareAmount,
    required double tripDistanceKm,
    required String paymentStatusSelection,
    double partialPaymentAmount = 0,
    bool markTripCompleted = false,
  }) async {
    final km = tripDistanceKm < 0 ? 0.0 : tripDistanceKm;
    final endKm = entry.startKm + km;

    var endDateTime = entry.endDateTime;
    final now = DateTime.now();
    if (markTripCompleted && now.isBefore(entry.endDateTime)) {
      endDateTime = now;
    }

    final billable = RentalEntry.billableTripAmount(
      rentFareAmount: rentFareAmount,
      fuelCost: entry.fuelCost,
      customerPaidFuelBill: entry.customerPaidFuelBill,
    );

    final extraPayment = partialPaymentAmount < 0 ? 0.0 : partialPaymentAmount;

    final double newAdvance;
    final String paymentStatus;
    switch (paymentStatusSelection) {
      case 'Paid':
        newAdvance = billable;
        paymentStatus = 'Paid';
      case 'Partial':
        newAdvance = entry.advanceReceived + extraPayment;
        paymentStatus = 'Partial';
      case 'Due':
        newAdvance = entry.advanceReceived;
        paymentStatus = 'Due';
      default:
        newAdvance = entry.advanceReceived;
        paymentStatus = 'Due';
    }

    final dueAmount = paymentStatus == 'Paid'
        ? 0.0
        : RentalEntry.computeDue(
            rentFareAmount: rentFareAmount,
            advanceReceived: newAdvance,
            fuelCost: entry.fuelCost,
            customerPaidFuelBill: entry.customerPaidFuelBill,
          );

    final updated = entry.copyWith(
      rentFareAmount: rentFareAmount,
      endKm: endKm,
      totalKm: km,
      endDateTime: endDateTime,
      advanceReceived: newAdvance,
      dueAmount: dueAmount < 0 ? 0.0 : dueAmount,
      paymentStatus: paymentStatus,
    );

    await _updateRental(updated);
    await _applyTripDistanceDeltaToVehicleOdometer(
      vehicleId: updated.vehicleId,
      deltaTripKm: updated.totalKm - entry.totalKm,
    );
  }

  Future<void> deleteRental(String id) async {
    try {
      await _deleteRental(id);
    } catch (error) {
      emit(RentalError(error.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
