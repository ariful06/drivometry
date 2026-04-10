import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Saves a vehicle document image from [sourcePath] to app documents under
/// vehicle_docs/[vehicleId]_[docType][ext]. Returns the stored file path, or null on failure.
Future<String?> saveVehicleDocument(
  String vehicleId,
  String docType,
  String sourcePath,
) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${dir.path}/vehicle_docs');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    final ext = sourcePath.contains('.')
        ? '.${sourcePath.split('.').last.toLowerCase()}'
        : '.jpg';
    final extSanitized = ext == '.jpg' || ext == '.jpeg' || ext == '.png'
        ? ext
        : '.jpg';
    final destPath = '${docsDir.path}/${vehicleId}_$docType$extSanitized';
    await File(sourcePath).copy(destPath);
    return destPath;
  } catch (_) {
    return null;
  }
}
