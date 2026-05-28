import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class UploadsPage extends StatefulWidget {
  const UploadsPage({super.key});

  @override
  State<UploadsPage> createState() => _UploadsPageState();
}

class _UploadsPageState extends State<UploadsPage> {
  final Set<String> _downloading = <String>{};
  final Set<String> _uploading = <String>{};

  static const _items = <_UploadItem>[
    _UploadItem(
      key: 'customers',
      title: 'Customers',
      subtitle: 'Bulk import customer records',
      icon: Icons.groups_rounded,
      templatePath: '/api/Customers/import-template',
      importPath: '/api/Customers/import',
    ),
    _UploadItem(
      key: 'daily-loans',
      title: 'Daily Loans',
      subtitle: 'Bulk import daily loan entries',
      icon: Icons.calendar_today_outlined,
      templatePath: '/api/DailyLoans/import-template',
      importPath: '/api/DailyLoans/import',
    ),
    _UploadItem(
      key: 'soft-loans',
      title: 'Soft Loans',
      subtitle: 'Bulk import soft loan entries',
      icon: Icons.handshake_outlined,
      templatePath: '/api/SoftLoans/import-template',
      importPath: '/api/SoftLoans/import',
    ),
    _UploadItem(
      key: 'repayments',
      title: 'Repayments',
      subtitle: 'Bulk import repayment records',
      icon: Icons.arrow_upward_rounded,
      templatePath: '/api/Repayments/import-template',
      importPath: '/api/Repayments/import',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uploads')),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          final downloading = _downloading.contains(item.key);
          final uploading = _uploading.contains(item.key);
          final busy = downloading || uploading;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.18),
                        child: Icon(item.icon),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => _downloadTemplate(item),
                          icon: downloading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: const Text('Download Template'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: busy ? null : () => _pickAndUpload(item),
                          icon: uploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded),
                          label: const Text('Upload File'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadTemplate(_UploadItem item) async {
    setState(() => _downloading.add(item.key));
    try {
      final template = await context
          .read<AppState>()
          .downloadImportTemplateByPath(item.templatePath);
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${template.filename}';
      final file = File(savePath);
      await file.writeAsBytes(template.bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} template downloaded.')),
      );
      await OpenFilex.open(savePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to download template: $e')));
    } finally {
      if (mounted) {
        setState(() => _downloading.remove(item.key));
      }
    }
  }

  Future<void> _pickAndUpload(_UploadItem item) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'xls', 'xlsx', 'doc', 'docx'],
      );
      if (result == null) return;

      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid file selected.')));
        return;
      }

      final confirmed = await _showFilePreview(path);
      if (confirmed != true) return;

      setState(() => _uploading.add(item.key));
      await context.read<AppState>().importFileToApiByPath(
        endpointPath: item.importPath,
        filePath: path,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} file uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _uploading.remove(item.key));
      }
    }
  }

  Future<bool?> _showFilePreview(String path) async {
    final file = File(path);
    final name = path.split(Platform.pathSeparator).last;
    final ext = name.split('.').last.toLowerCase();

    Widget content;
    if (ext == 'xlsx' || ext == 'xls') {
      try {
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final sheetName =
            excel.tables.keys.isNotEmpty ? excel.tables.keys.first : null;
        final sheet = sheetName != null ? excel.tables[sheetName] : null;
        final rows = sheet?.rows ?? const [];
        final previewRows = rows.take(10).toList();

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (sheetName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Sheet: $sheetName (first ${previewRows.length} rows)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 280),
                  child: SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(color: const Color(0xFFE0E0E0)),
                      children: previewRows.map((row) {
                        final cells = row
                            .map((c) => (c?.value ?? '').toString())
                            .toList();
                        return TableRow(
                          children: cells
                              .map(
                                (text) => Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    text,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } catch (_) {
        content = Text(
          'File: $name\n\nUnable to preview this Excel file, but you can still upload it.',
          style: const TextStyle(fontSize: 13),
        );
      }
    } else {
      final sizeBytes = await file.length();
      final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);
      content = Text(
        'File: $name\nType: $ext\nSize: $sizeKb KB\n\nOnly Excel files can show a row preview. This file can still be uploaded if you continue.',
        style: const TextStyle(fontSize: 13),
      );
    }

    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Preview before upload'),
          content: SizedBox(width: double.maxFinite, child: content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }
}

class _UploadItem {
  const _UploadItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.templatePath,
    required this.importPath,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String templatePath;
  final String importPath;
}
