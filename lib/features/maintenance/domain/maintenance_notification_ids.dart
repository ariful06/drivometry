/// Stable Android/iOS notification group base ids derived from maintenance
/// entry UUIDs (persisted IDs are skipped so cancel/re-schedule stays correct).
final class MaintenanceNotificationIds {
  MaintenanceNotificationIds._();

  static int odometerBurstBase(String maintenanceEntryId) {
    final hashedPositive = maintenanceEntryId.hashCode & 0x7FFFFFFF;
    return hashedPositive < 1 ? 1 : hashedPositive;
  }

  static int dateBurstBase(String maintenanceEntryId) {
    final scrambledPositive =
        (maintenanceEntryId.hashCode ^ 0xBADC0FFE) & 0x7FFFFFFF;
    return scrambledPositive < 1 ? 2 : scrambledPositive;
  }
}
