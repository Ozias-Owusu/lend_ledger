import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A picked import file copied into app-accessible storage (required on Android).
class StagedImportFile {
  const StagedImportFile({
    required this.path,
    required this.displayName,
    required this.bytes,
  });

  final String path;
  final String displayName;
  final List<int> bytes;
}

class ImportFileStaging {
  ImportFileStaging._();

  /// Reads bytes from [file] (memory or path) and writes a copy under app temp dir.
  static Future<StagedImportFile> stage(PlatformFile file) async {
    final bytes = await _readBytes(file);
    if (bytes.isEmpty) {
      throw const ImportFileReadException(
        'The selected file is empty.',
      );
    }

    final displayName = file.name.trim().isNotEmpty
        ? file.name.trim()
        : 'import.xlsx';
    final ext = p.extension(displayName).toLowerCase();
    final safeBase = p.basenameWithoutExtension(displayName)
        .replaceAll(RegExp(r'[^\w\-. ]'), '_')
        .trim();
    final fileName = '${safeBase.isEmpty ? 'import' : safeBase}'
        '${ext.isNotEmpty ? ext : '.xlsx'}';

    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'import_${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final outFile = File(outPath);
    await outFile.writeAsBytes(bytes, flush: true);

    return StagedImportFile(
      path: outPath,
      displayName: displayName,
      bytes: bytes,
    );
  }

  static Future<List<int>> _readBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes!;
    }

    final path = file.path;
    if (path != null && path.isNotEmpty) {
      try {
        final ioFile = File(path);
        if (await ioFile.exists()) {
          return ioFile.readAsBytes();
        }
      } catch (_) {
        // Fall through — path may be inaccessible on Android.
      }
    }

    throw const ImportFileReadException(
      'Could not read the selected file. Try picking it again or save a copy '
      'to Downloads first.',
    );
  }
}

class ImportFileReadException implements Exception {
  const ImportFileReadException(this.message);
  final String message;

  @override
  String toString() => message;
}
