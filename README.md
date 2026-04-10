# Drivometry

A Flutter app for tracking vehicle expenses, fuel logs, and maintenance.

## Architecture

The app uses **Clean Architecture** with separate **presentation**, **domain**, and **data** layers so the data layer can be swapped (e.g. to Hive or Isar) without changing UI or business logic. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Running on your iPhone (from Mac)

1. Connect your iPhone via USB (or use wireless debugging).
2. Open the project in your editor and run:
   ```bash
   flutter run
   ```
   Select your iPhone when prompted, or use:
   ```bash
   flutter run -d <device-id>
   ```
   List devices with `flutter devices`.
3. For a **release** (production) build on device:
   ```bash
   flutter run --release
   ```
   Or build an IPA: `flutter build ipa` (then use Xcode or Transporter to install).

## Production build

- **Release mode** disables debug banners and improves performance. Use `flutter run --release` or `flutter build apk` / `flutter build ios`.
- Database logging and verbose init logs are only enabled in debug (`kDebugMode`).
- If app init fails (e.g. DB or notifications), users see a friendly error screen instead of a crash.

## Getting Started

- [Flutter documentation](https://docs.flutter.dev/)
- [Architecture and data-layer swap](docs/ARCHITECTURE.md)

## Todo 
[ ] Service History Export (PDF, Excel sheet, share with someone)
[ ] Receipt Scanning AI (OCR fuel receipt scanner)
[ ] Smart Alerts
(Brake pads usually last 25k km .Your car at 23k km) 
Notification: Brake pads likely need replacement soon
[ ] Maintenance Timeline