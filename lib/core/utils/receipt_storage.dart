import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Saves a receipt image from [sourcePath] to app documents under receipts/[id][ext].
/// Returns the stored file path, or null on failure.
Future<String?> saveReceiptImage(String entryId, String sourcePath) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    final ext = sourcePath.contains('.')
        ? '.${sourcePath.split('.').last.toLowerCase()}'
        : '.jpg';
    final extSanitized =
        ext == '.jpg' || ext == '.jpeg' || ext == '.png' ? ext : '.jpg';
    final destPath = '${receiptsDir.path}/$entryId$extSanitized';
    await File(sourcePath).copy(destPath);
    return destPath;
  } catch (_) {
    return null;
  }
}
