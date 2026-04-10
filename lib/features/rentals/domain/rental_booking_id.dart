import 'entities/rental_entry.dart';

/// Generates the next booking number in **1 … 1_000_000** (unique among existing entries).
class RentalBookingId {
  RentalBookingId._();

  static String next(Iterable<RentalEntry> entries) {
    final used = <int>{};
    for (final e in entries) {
      final n = int.tryParse(e.bookingId.replaceAll('#', '').trim());
      if (n != null && n >= 1 && n <= 1000000) used.add(n);
    }
    var max = 0;
    for (final n in used) {
      if (n > max) max = n;
    }
    var candidate = max + 1;
    if (candidate > 1000000) candidate = 1;
    for (var i = 0; i < 1000000; i++) {
      if (!used.contains(candidate)) return '$candidate';
      candidate++;
      if (candidate > 1000000) candidate = 1;
    }
    return '1';
  }
}
