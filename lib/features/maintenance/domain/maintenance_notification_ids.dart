/// Stable Android/iOS notification group base ids derived from maintenance
/// entry UUIDs (persisted IDs are skipped so cancel/re-schedule stays correct).
final class MaintenanceNotificationIds {
  MaintenanceNotificationIds._();

  /// FNV-1a 32-bit: deterministic across runs and Dart versions, unlike
  /// [String.hashCode].
  static int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static int odometerBurstBase(String maintenanceEntryId) {
    final hashedPositive = _stableHash(maintenanceEntryId) & 0x7FFFFFFF;
    return hashedPositive < 1 ? 1 : hashedPositive;
  }

  static int dateBurstBase(String maintenanceEntryId) {
    final scrambledPositive =
        (_stableHash(maintenanceEntryId) ^ 0xBADC0FFE) & 0x7FFFFFFF;
    return scrambledPositive < 1 ? 2 : scrambledPositive;
  }
}
