import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'import_preview_page.dart';

class UploadsPage extends StatefulWidget {
  const UploadsPage({super.key});

  @override
  State<UploadsPage> createState() => _UploadsPageState();
}

class _UploadsPageState extends State<UploadsPage> {
  final Set<String> _downloading = <String>{};

  static const _items = <_UploadItem>[
    _UploadItem(
      key: 'customers',
      title: 'Customers',
      subtitle: 'Bulk import customer records',
      icon: Icons.groups_rounded,
      templatePath: '/api/Customers/import-template',
      importPath: '/api/Customers/import',
      validateCustomers: true,
      excelOnly: true,
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
                          onPressed:
                              downloading ? null : () => _downloadTemplate(item),
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
                          onPressed:
                              downloading ? null : () => _pickAndPreview(item),
                          icon: const Icon(Icons.upload_file_rounded),
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
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download template: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading.remove(item.key));
      }
    }
  }

  Future<void> _pickAndPreview(_UploadItem item) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: item.excelOnly
            ? const ['xlsx']
            : const ['xlsx', 'xls'],
      );
      if (result == null) return;

      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file selected.')),
        );
        return;
      }

      final ext = path.split('.').last.toLowerCase();
      if (item.excelOnly && ext != 'xlsx') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer import requires an .xlsx Excel file.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ImportPreviewPage(
            title: item.title,
            filePath: path,
            importPath: item.importPath,
            validateCustomers: item.validateCustomers,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
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
    this.validateCustomers = false,
    this.excelOnly = false,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String templatePath;
  final String importPath;
  final bool validateCustomers;
  final bool excelOnly;
}
