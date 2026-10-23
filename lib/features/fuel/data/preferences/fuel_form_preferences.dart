import 'package:shared_preferences/shared_preferences.dart';

/// How the user last filled in the fuel form for a vehicle.
class FuelFormDefaults {
  const FuelFormDefaults({
    this.useTripMode = true,
    this.useTotalPaidForQuantity = false,
  });

  /// `true` = km since last fill; `false` = dashboard odometer.
  final bool useTripMode;

  /// `true` = quantity from total paid; `false` = liters.
  final bool useTotalPaidForQuantity;
}

/// Per-vehicle fuel form modes, so the next fill opens the way the last one
/// was entered. Missing or unreadable preferences fall back to the defaults.
class FuelFormPreferences {
  const FuelFormPreferences();

  static String _tripKey(String vehicleId) => 'fuel_form_trip_mode_$vehicleId';
  static String _totalPaidKey(String vehicleId) =>
      'fuel_form_total_paid_$vehicleId';

  Future<FuelFormDefaults> load(String vehicleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return FuelFormDefaults(
        useTripMode: prefs.getBool(_tripKey(vehicleId)) ?? true,
        useTotalPaidForQuantity:
            prefs.getBool(_totalPaidKey(vehicleId)) ?? false,
      );
    } catch (_) {
      return const FuelFormDefaults();
    }
  }

  Future<void> save(String vehicleId, FuelFormDefaults defaults) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tripKey(vehicleId), defaults.useTripMode);
      await prefs.setBool(
        _totalPaidKey(vehicleId),
        defaults.useTotalPaidForQuantity,
      );
    } catch (_) {
      // Remembering modes is a convenience; never block saving a fill.
    }
  }
}
