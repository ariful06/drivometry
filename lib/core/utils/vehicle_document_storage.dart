import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

String _sanitizeImageExtension(String sourcePath) {
  final ext = sourcePath.contains('.')
      ? '.${sourcePath.split('.').last.toLowerCase()}'
      : '.jpg';
  if (ext == '.jpg' || ext == '.jpeg' || ext == '.png') {
    return ext;
  }
  return '.jpg';
}

Future<Directory> _vehicleDocsDirectory() async {
  final dir = await getApplicationDocumentsDirectory();
  final docsDir = Directory('${dir.path}/vehicle_docs');
  if (!await docsDir.exists()) {
    await docsDir.create(recursive: true);
  }
  return docsDir;
}

/// Persists a picked image right away. Camera/gallery paths on Android are
/// often under cache and can disappear before save — read bytes first.
Future<String?> persistVehicleDocumentFromPick(
  String vehicleId,
  String docType,
  XFile file,
) async {
  try {
    final docsDir = await _vehicleDocsDirectory();
    final ext = _sanitizeImageExtension(file.path);
    final destPath = '${docsDir.path}/${vehicleId}_$docType$ext';
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    await File(destPath).writeAsBytes(bytes, flush: true);
    return destPath;
  } catch (_) {
    if (file.path.isEmpty) return null;
    return saveVehicleDocument(vehicleId, docType, file.path);
  }
}

/// Saves a vehicle document image from [sourcePath] to app documents under
/// vehicle_docs/[vehicleId]_[docType][ext]. Returns the stored file path, or null on failure.
Future<String?> saveVehicleDocument(
  String vehicleId,
  String docType,
  String sourcePath,
) async {
  try {
    final docsDir = await _vehicleDocsDirectory();
    final ext = _sanitizeImageExtension(sourcePath);
    final destPath = '${docsDir.path}/${vehicleId}_$docType$ext';
    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      await sourceFile.copy(destPath);
      return destPath;
    }
    return null;
  } catch (_) {
    return null;
  }
}
