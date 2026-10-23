import 'package:drivometry/core/settings/app_settings.dart';
import 'package:drivometry/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.instance.resetForTest();
  });

  test('defaults: taka, km, litres', () {
    expect(Formatters.formatCurrency(1234.5), '৳ 1,234.50');
    expect(Formatters.formatDistance(100), '100.0 km');
    expect(Formatters.formatLiters(10), '10.00 L');
    expect(Formatters.formatFuelEfficiency(15), '15.00 km/L');
    expect(Formatters.formatCostPerDistance(12), '৳ 12.00/km');
  });

  test('miles and gallons convert for display only', () async {
    final s = AppSettings.instance;
    await s.setCurrencySymbol('\$');
    await s.setDistanceUnit(DistanceUnit.mile);
    await s.setVolumeUnit(VolumeUnit.gallon);
    expect(Formatters.formatCurrency(5), '\$ 5.00');
    expect(Formatters.formatDistance(160.9344), '100.0 mi');
    expect(Formatters.formatLiters(3.785411784), '1.00 gal');
    // 10 km/L ≈ 23.52 mpg (US)
    expect(Formatters.formatFuelEfficiency(10), '23.52 mpg');
    expect(Formatters.formatCostPerDistance(1), '\$ 1.61/mi');
  });

  test('settings persist and reload', () async {
    await AppSettings.instance.setDistanceUnit(DistanceUnit.mile);
    AppSettings.instance.resetForTest();
    await AppSettings.instance.load();
    expect(AppSettings.instance.distanceUnit, DistanceUnit.mile);
  });
}
