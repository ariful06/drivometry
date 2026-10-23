// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

import '../constants/energy_type.dart';
import '../settings/app_settings.dart';

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

  static AppSettings get _settings => AppSettings.instance;

  static String formatCurrency(double amount, {String? symbol}) {
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '${symbol ?? _settings.currencySymbol} $formatted';
  }

  /// Converts a stored distance in km to the display unit.
  static double distanceToDisplay(double km) =>
      _settings.distanceUnit == DistanceUnit.mile
          ? km / AppSettings.kmPerMile
          : km;

  /// Converts stored litres to the display volume unit.
  static double volumeToDisplay(double liters) =>
      _settings.volumeUnit == VolumeUnit.gallon
          ? liters / AppSettings.litersPerGallon
          : liters;

  static String formatDistance(double km) =>
      '${distanceToDisplay(km).toStringAsFixed(1)} ${_settings.distanceLabel}';

  /// Efficiency is stored as km/L; shown as km/L, mpg, mi/L or km/gal.
  static String formatFuelEfficiency(double kmPerLiter) {
    final value = distanceToDisplay(kmPerLiter) /
        volumeToDisplay(1); // distance per displayed volume unit
    final unit = switch ((_settings.distanceUnit, _settings.volumeUnit)) {
      (DistanceUnit.km, VolumeUnit.liter) => 'km/L',
      (DistanceUnit.mile, VolumeUnit.gallon) => 'mpg',
      (DistanceUnit.mile, VolumeUnit.liter) => 'mi/L',
      (DistanceUnit.km, VolumeUnit.gallon) => 'km/gal',
    };
    return '${value.toStringAsFixed(2)} $unit';
  }

  /// Cost per displayed distance unit, e.g. `৳ 12.50/km`.
  static String formatCostPerDistance(double costPerKm) {
    final perUnit = costPerKm *
        (_settings.distanceUnit == DistanceUnit.mile
            ? AppSettings.kmPerMile
            : 1);
    return '${_settings.currencySymbol} ${perUnit.toStringAsFixed(2)}/${_settings.distanceLabel}';
  }

  static String formatLiters(double liters) =>
      '${volumeToDisplay(liters).toStringAsFixed(2)} ${_settings.volumeLabel}';

  /// Amount of [type]: litres follow the volume setting; kg and kWh as is.
  static String formatQuantity(double amount, EnergyType type) => type.isLiquid
      ? formatLiters(amount)
      : '${amount.toStringAsFixed(2)} ${type.unit}';

  /// Efficiency in distance per unit of [type], e.g. `km/L`, `mpg`, `km/kg`.
  static String formatEfficiencyFor(double kmPerUnit, EnergyType type) {
    if (type.isLiquid) return formatFuelEfficiency(kmPerUnit);
    final value = distanceToDisplay(kmPerUnit);
    return '${value.toStringAsFixed(2)} ${_settings.distanceLabel}/${type.unit}';
  }

  /// Price per unit of [type], e.g. `৳ 110.00/L`, `৳ 45.00/kg`.
  static String formatUnitPrice(double pricePerUnit, EnergyType type) {
    final perUnit = type.isLiquid && _settings.volumeUnit == VolumeUnit.gallon
        ? pricePerUnit * AppSettings.litersPerGallon
        : pricePerUnit;
    final unit = type.isLiquid ? _settings.volumeLabel : type.unit;
    return '${_settings.currencySymbol} ${perUnit.toStringAsFixed(2)}/$unit';
  }

  /// Short efficiency unit for [type], e.g. `km/L`, `mpg`, `km/kWh`.
  static String efficiencyUnitFor(EnergyType type) =>
      formatEfficiencyFor(1, type).split(' ').last;

  /// Usage per 100 distance units, e.g. `6.5 L/100 km`, `12.0 kWh/100 km`.
  static String formatPer100(double amountPer100Km, EnergyType type) {
    final unit = type.isLiquid ? _settings.volumeLabel : type.unit;
    final amount = type.isLiquid
        ? volumeToDisplay(amountPer100Km) / distanceToDisplay(1)
        : amountPer100Km / distanceToDisplay(1);
    return '${amount.toStringAsFixed(1)} $unit/100 ${_settings.distanceLabel}';
  }

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
