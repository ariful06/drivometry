// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'Drivometry';
  static const String appVersion = '1.0.0';

  /// Rentals are hidden for now (next phase). Code and data stay in place;
  /// flip to true to restore the Rental tab.
  static const bool rentalsEnabled = false;

  // Database
  static const String isarDbName = 'drivometry_db';
  static const int isarSchemaVersion = 1;

  // Notification
  static const String notificationChannelId = 'drivometry_maintenance';
  static const String notificationChannelName = 'Maintenance Reminders';
  static const String notificationChannelDesc =
      'Reminders for upcoming vehicle maintenance';

  // Shared Prefs / Settings
  static const String prefThemeMode = 'theme_mode';
  static const String prefDistanceUnit = 'distance_unit';
  static const String prefCurrencySymbol = 'currency_symbol';

  // Defaults
  static const String defaultCurrency = '৳';
  static const String defaultDistanceUnit = 'km';

  // Analytics periods
  static const String periodWeekly = 'Weekly';
  static const String periodMonthly = 'Monthly';
  static const String periodYearly = 'Yearly';
  static const String periodLifetime = 'Lifetime';

  // Vehicle types
  static const String vehicleTypeCar = 'Car';
  static const String vehicleTypeBike = 'Bike';
  static const String vehicleTypeOther = 'Other';
}
