class RentalEntry {
  const RentalEntry({
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
  /// Numeric string in range 1–1_000_000; prefix with `#` in UI.
  final String bookingId;
  final DateTime bookingDate;
  final String customerName;
  final String phone;
  final String fromLocation;
  final String toLocation;
  final String tripType;
  /// When [tripType] is Trip: `Single trip` or `Round trip`; otherwise empty.
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
  /// `Self` or `Driver`.
  final String driverMode;
  final String? driverName;
  /// Driver phone (auto-filled when driver directory selection is used).
  final String? driverPhone;
  final double fuelCost;
  /// When true, [fuelCost] is deducted from the trip billable amount before due.
  final bool customerPaidFuelBill;
  final String? notes;

  /// Amount the customer is charged before advance: fare minus customer-paid fuel.
  static double billableTripAmount({
    required double rentFareAmount,
    required double fuelCost,
    required bool customerPaidFuelBill,
  }) {
    final fuelOffset = customerPaidFuelBill ? fuelCost : 0;
    return rentFareAmount - fuelOffset;
  }

  static double computeDue({
    required double rentFareAmount,
    required double advanceReceived,
    required double fuelCost,
    required bool customerPaidFuelBill,
  }) {
    final billable = billableTripAmount(
      rentFareAmount: rentFareAmount,
      fuelCost: fuelCost,
      customerPaidFuelBill: customerPaidFuelBill,
    );
    return billable - advanceReceived;
  }

  RentalEntry copyWith({
    String? id,
    String? vehicleId,
    String? bookingId,
    DateTime? bookingDate,
    String? customerName,
    String? phone,
    String? fromLocation,
    String? toLocation,
    String? tripType,
    String? tripLeg,
    DateTime? startDateTime,
    DateTime? endDateTime,
    double? startKm,
    double? endKm,
    double? totalKm,
    double? rentFareAmount,
    double? advanceReceived,
    double? dueAmount,
    String? paymentStatus,
    String? fuelProvidedBy,
    String? driverMode,
    String? driverName,
    String? driverPhone,
    double? fuelCost,
    bool? customerPaidFuelBill,
    String? notes,
  }) =>
      RentalEntry(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        bookingId: bookingId ?? this.bookingId,
        bookingDate: bookingDate ?? this.bookingDate,
        customerName: customerName ?? this.customerName,
        phone: phone ?? this.phone,
        fromLocation: fromLocation ?? this.fromLocation,
        toLocation: toLocation ?? this.toLocation,
        tripType: tripType ?? this.tripType,
        tripLeg: tripLeg ?? this.tripLeg,
        startDateTime: startDateTime ?? this.startDateTime,
        endDateTime: endDateTime ?? this.endDateTime,
        startKm: startKm ?? this.startKm,
        endKm: endKm ?? this.endKm,
        totalKm: totalKm ?? this.totalKm,
        rentFareAmount: rentFareAmount ?? this.rentFareAmount,
        advanceReceived: advanceReceived ?? this.advanceReceived,
        dueAmount: dueAmount ?? this.dueAmount,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        fuelProvidedBy: fuelProvidedBy ?? this.fuelProvidedBy,
        driverMode: driverMode ?? this.driverMode,
        driverName: driverName ?? this.driverName,
        driverPhone: driverPhone ?? this.driverPhone,
        fuelCost: fuelCost ?? this.fuelCost,
        customerPaidFuelBill: customerPaidFuelBill ?? this.customerPaidFuelBill,
        notes: notes ?? this.notes,
      );
}
