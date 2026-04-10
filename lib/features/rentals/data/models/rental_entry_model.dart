import '../../domain/entities/rental_entry.dart';

class RentalEntryModel {
  const RentalEntryModel({
    required this.id,
    required this.vehicleId,
    required this.bookingId,
    required this.bookingDate,
    required this.customerName,
    required this.phone,
    required this.fromLocation,
    required this.toLocation,
    required this.tripType,
    required this.tripLeg,
    required this.startDateTime,
    required this.endDateTime,
    required this.startKm,
    required this.endKm,
    required this.totalKm,
    required this.rentFareAmount,
    required this.advanceReceived,
    required this.dueAmount,
    required this.paymentStatus,
    required this.fuelProvidedBy,
    required this.driverMode,
    required this.fuelCost,
    required this.customerPaidFuelBill,
    this.driverName,
    this.driverPhone,
    this.notes,
  });

  final String id;
  final String vehicleId;
  final String bookingId;
  final DateTime bookingDate;
  final String customerName;
  final String phone;
  final String fromLocation;
  final String toLocation;
  final String tripType;
  final String tripLeg;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double startKm;
  final double endKm;
  final double totalKm;
  final double rentFareAmount;
  final double advanceReceived;
  final double dueAmount;
  final String paymentStatus;
  final String fuelProvidedBy;
  final String driverMode;
  final String? driverName;
  final String? driverPhone;
  final double fuelCost;
  final bool customerPaidFuelBill;
  final String? notes;

  factory RentalEntryModel.fromMap(Map<String, dynamic> map) {
    final rawBooking = map['booking_id'];
    final bookingStr = rawBooking is int ? '$rawBooking' : rawBooking as String;
    final cleanBooking = bookingStr.replaceAll('#', '').trim();

    return RentalEntryModel(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      bookingId: cleanBooking.isEmpty ? bookingStr : cleanBooking,
      bookingDate: DateTime.parse(map['booking_date'] as String),
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String,
      fromLocation: map['from_location'] as String,
      toLocation: map['to_location'] as String,
      tripType: map['trip_type'] as String,
      tripLeg: map['trip_leg'] as String? ?? '',
      startDateTime: DateTime.parse(map['start_date_time'] as String),
      endDateTime: DateTime.parse(map['end_date_time'] as String),
      startKm: (map['start_km'] as num).toDouble(),
      endKm: (map['end_km'] as num).toDouble(),
      totalKm: (map['total_km'] as num).toDouble(),
      rentFareAmount: (map['rent_fare_amount'] as num).toDouble(),
      advanceReceived: (map['advance_received'] as num).toDouble(),
      dueAmount: (map['due_amount'] as num).toDouble(),
      paymentStatus: map['payment_status'] as String,
      fuelProvidedBy: map['fuel_provided_by'] as String,
      driverMode: map['driver_mode'] as String? ?? 'Self',
      driverName: map['driver_name'] as String?,
      driverPhone: map['driver_phone'] as String?,
      fuelCost: (map['fuel_cost'] as num?)?.toDouble() ?? 0,
      customerPaidFuelBill: (map['customer_paid_fuel_bill'] as int?) == 1,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'booking_id': bookingId,
        'booking_date': bookingDate.toIso8601String(),
        'customer_name': customerName,
        'phone': phone,
        'from_location': fromLocation,
        'to_location': toLocation,
        'trip_type': tripType,
        'trip_leg': tripLeg,
        'start_date_time': startDateTime.toIso8601String(),
        'end_date_time': endDateTime.toIso8601String(),
        'start_km': startKm,
        'end_km': endKm,
        'total_km': totalKm,
        'rent_fare_amount': rentFareAmount,
        'advance_received': advanceReceived,
        'due_amount': dueAmount,
        'payment_status': paymentStatus,
        'fuel_provided_by': fuelProvidedBy,
        'driver_mode': driverMode,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'fuel_cost': fuelCost,
        'customer_paid_fuel_bill': customerPaidFuelBill ? 1 : 0,
        'notes': notes,
      };

  factory RentalEntryModel.fromEntity(RentalEntry e) => RentalEntryModel(
        id: e.id,
        vehicleId: e.vehicleId,
        bookingId: e.bookingId,
        bookingDate: e.bookingDate,
        customerName: e.customerName,
        phone: e.phone,
        fromLocation: e.fromLocation,
        toLocation: e.toLocation,
        tripType: e.tripType,
        tripLeg: e.tripLeg,
        startDateTime: e.startDateTime,
        endDateTime: e.endDateTime,
        startKm: e.startKm,
        endKm: e.endKm,
        totalKm: e.totalKm,
        rentFareAmount: e.rentFareAmount,
        advanceReceived: e.advanceReceived,
        dueAmount: e.dueAmount,
        paymentStatus: e.paymentStatus,
        fuelProvidedBy: e.fuelProvidedBy,
        driverMode: e.driverMode,
        driverName: e.driverName,
        driverPhone: e.driverPhone,
        fuelCost: e.fuelCost,
        customerPaidFuelBill: e.customerPaidFuelBill,
        notes: e.notes,
      );

  RentalEntry toEntity() => RentalEntry(
        id: id,
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
        driverPhone: driverPhone,
        fuelCost: fuelCost,
        customerPaidFuelBill: customerPaidFuelBill,
        notes: notes,
      );
}
