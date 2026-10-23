// lib/core/settings/app_settings.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DistanceUnit { km, mile }

enum VolumeUnit { liter, gallon }

/// Global display preferences (currency and units). Data is always stored in
/// km and litres; these settings only change how values are shown.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const _currencyKey = 'settings_currency_symbol';
  static const _distanceKey = 'settings_distance_unit';
  static const _volumeKey = 'settings_volume_unit';

  static const kmPerMile = 1.609344;
  static const litersPerGallon = 3.785411784;

  /// Currencies offered in Settings (symbol, label).
  static const currencies = <(String, String)>[
    ('৳', 'Bangladeshi Taka (৳)'),
    ('\$', 'US Dollar (\$)'),
    ('€', 'Euro (€)'),
    ('£', 'Pound Sterling (£)'),
    ('₹', 'Indian Rupee (₹)'),
    ('Rs', 'Rupee (Rs)'),
    ('AED', 'UAE Dirham (AED)'),
    ('SAR', 'Saudi Riyal (SAR)'),
  ];

  String _currencySymbol = '৳';
  DistanceUnit _distanceUnit = DistanceUnit.km;
  VolumeUnit _volumeUnit = VolumeUnit.liter;

  String get currencySymbol => _currencySymbol;
  DistanceUnit get distanceUnit => _distanceUnit;
  VolumeUnit get volumeUnit => _volumeUnit;

  String get distanceLabel => _distanceUnit == DistanceUnit.km ? 'km' : 'mi';
  String get volumeLabel => _volumeUnit == VolumeUnit.liter ? 'L' : 'gal';

  /// Bumped on every change so the app can rebuild with fresh formatting.
  int get revision => _revision;
  int _revision = 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString(_currencyKey) ?? _currencySymbol;
    _distanceUnit = prefs.getString(_distanceKey) == 'mile'
        ? DistanceUnit.mile
        : DistanceUnit.km;
    _volumeUnit = prefs.getString(_volumeKey) == 'gallon'
        ? VolumeUnit.gallon
        : VolumeUnit.liter;
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    _changed();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
  }

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    _distanceUnit = unit;
    _changed();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _distanceKey, unit == DistanceUnit.mile ? 'mile' : 'km');
  }

  Future<void> setVolumeUnit(VolumeUnit unit) async {
    _volumeUnit = unit;
    _changed();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _volumeKey, unit == VolumeUnit.gallon ? 'gallon' : 'liter');
  }

  /// Test helper: reset to defaults without touching storage.
  @visibleForTesting
  void resetForTest() {
    _currencySymbol = '৳';
    _distanceUnit = DistanceUnit.km;
    _volumeUnit = VolumeUnit.liter;
    _revision = 0;
  }

  void _changed() {
    _revision++;
    notifyListeners();
  }
}
