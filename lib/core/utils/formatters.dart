// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _shortDateFormat = DateFormat('dd MMM');
  static final _monthYearFormat = DateFormat('MMM yyyy');
  static final _fullDateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatDateTime(DateTime date) =>
      _fullDateTimeFormat.format(date);

  static String formatCurrency(double amount, {String symbol = '৳'}) {
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '$symbol $formatted';
  }

  static String formatDistance(double km, {String unit = 'km'}) {
    if (unit == 'mile') {
      final miles = km * 0.621371;
      return '${miles.toStringAsFixed(1)} mi';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static String formatFuelEfficiency(double value, {String unit = 'km'}) {
    if (unit == 'mile') {
      final mpg = value * 0.621371;
      return '${mpg.toStringAsFixed(2)} mpg';
    }
    return '${value.toStringAsFixed(2)} km/L';
  }

  static String formatLiters(double liters) => '${liters.toStringAsFixed(2)} L';

  static String formatNumber(double value) =>
      NumberFormat('#,##0.##').format(value);

  /// Display booking reference with a `#` prefix (storage uses digits only).
  static String formatBookingId(String bookingId) {
    final t = bookingId.trim();
    if (t.isEmpty) return '#—';
    return t.startsWith('#') ? t : '#$t';
  }

  static String relativeDays(DateTime date) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final local = date.toLocal();
    final dateOnly = DateTime(local.year, local.month, local.day);
    final diff = dateOnly.difference(startOfToday).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff <= 365) return 'In $diff days';
    if (diff < 0 && diff >= -365) return '${diff.abs()} days ago';
    if (diff > 365) return 'In ${(diff / 365).floor()} yr';
    return 'Overdue';
  }
}
