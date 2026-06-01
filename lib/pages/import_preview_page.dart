import 'package:flutter/material.dart';

import 'package:lend_ledger/core/import/customer_import_validator.dart';

import 'package:lend_ledger/core/import/excel_import_parser.dart';

import 'package:lend_ledger/state/app_state.dart';

import 'package:lend_ledger/theme/theme.dart';

import 'package:lend_ledger/pages/import_results_page.dart';

import 'package:lend_ledger/utils/snackbar_utils.dart';

import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';

import 'package:provider/provider.dart';



/// Full-screen preview and client-side validation before bulk upload.

class ImportPreviewPage extends StatefulWidget {

  const ImportPreviewPage({

    super.key,

    required this.title,

    required this.filePath,

    required this.fileName,

    required this.importPath,

    required this.validateCustomers,

  });



  final String title;

  final String filePath;

  final String fileName;

  final String importPath;

  final bool validateCustomers;



  @override

  State<ImportPreviewPage> createState() => _ImportPreviewPageState();

}



class _ImportPreviewPageState extends State<ImportPreviewPage> {

  ExcelSheetData? _sheet;

  List<ExcelDataRow> _dataRows = const [];

  List<CustomerImportValidationIssue> _clientIssues = const [];

  String? _loadError;

  bool _uploading = false;



  @override

  void initState() {

    super.initState();

    _loadSheet();

  }



  void _loadSheet() {

    try {

      final sheet = ExcelImportParser.parseFile(
        widget.filePath,
        fileName: widget.fileName,
      );

      final issues = widget.validateCustomers

          ? CustomerImportValidator.validateSheet(sheet)

          : const <CustomerImportValidationIssue>[];

      setState(() {

        _sheet = sheet;

        _dataRows = ExcelImportParser.dataRows(sheet);

        _clientIssues = issues;

        _loadError = null;

      });

    } catch (e) {

      setState(() {

        _loadError = e.toString();

        _sheet = null;

        _dataRows = const [];

        _clientIssues = const [];

      });

    }

  }



  Set<int> get _issueRows =>

      _clientIssues.map((e) => e.rowNumber).where((n) => n > 0).toSet();



  bool get _hasClientErrors => _clientIssues.isNotEmpty;



  Future<void> _upload() async {

    if (_hasClientErrors || _sheet == null || _loadError != null) return;

    setState(() => _uploading = true);

    try {

      final result = await context.read<AppState>().importFileToApiByPath(

        endpointPath: widget.importPath,

        filePath: widget.filePath,

      );

      if (!mounted) return;

      await Navigator.pushReplacement<void, void>(

        context,

        MaterialPageRoute(

          builder: (_) => ImportResultsPage(

            title: widget.title,

            result: result,

          ),

        ),

      );

    } catch (e) {

      if (!mounted) return;

      SnackbarUtils.showError(context, e, title: 'Upload failed');

    } finally {

      if (mounted) setState(() => _uploading = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    if (_loadError != null) {

      return Scaffold(

        body: AuthAnimatedBackground(

          child: SafeArea(

            child: Padding(

              padding: const EdgeInsets.all(24),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  IconButton(

                    alignment: Alignment.centerLeft,

                    onPressed: () => Navigator.pop(context),

                    icon: const Icon(Icons.arrow_back_rounded),

                  ),

                  const SizedBox(height: 16),

                  Text(

                    'Could not read file',

                    style: AppTheme.display(fontSize: 24),

                  ),

                  const SizedBox(height: 12),

                  Text(

                    'The Excel file could not be opened. Use the template from '

                    'Uploads and save it as .xlsx, then try again.',

                    style: AppTheme.body(fontSize: 14),

                  ),

                  const Spacer(),

                  FilledButton(

                    onPressed: () => Navigator.pop(context),

                    style: FilledButton.styleFrom(

                      backgroundColor: AppTheme.softRose,

                    ),

                    child: const Text('Go back'),

                  ),

                ],

              ),

            ),

          ),

        ),

      );

    }



    final sheet = _sheet!;

    final previewRows = sheet.rows.take(25).toList();



    return Scaffold(

      body: AuthAnimatedBackground(

        child: SafeArea(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Padding(

                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),

                child: Row(

                  children: [

                    IconButton(

                      onPressed: _uploading ? null : () => Navigator.pop(context),

                      icon: const Icon(Icons.arrow_back_rounded),

                    ),

                    Expanded(

                      child: Text(

                        'Preview ${widget.title}',

                        style: AppTheme.display(fontSize: 24),

                      ),

                    ),

                  ],

                ),

              ),

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Text(

                  sheet.fileName,

                  style: AppTheme.body(fontSize: 13, color: AppTheme.textMuted),

                ),

              ),

              if (_hasClientErrors) ...[

                const SizedBox(height: 12),

                _ClientIssuesBanner(issues: _clientIssues),

              ] else if (_dataRows.isNotEmpty) ...[

                const SizedBox(height: 12),

                Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: Material(

                    color: AppTheme.mintGray.withValues(alpha: 0.35),

                    borderRadius: BorderRadius.circular(12),

                    child: Padding(

                      padding: const EdgeInsets.all(12),

                      child: Row(

                        children: [

                          Icon(

                            Icons.check_circle_outline,

                            color: AppTheme.softRose.withValues(alpha: 0.9),

                          ),

                          const SizedBox(width: 10),

                          Expanded(

                            child: Text(

                              '${_dataRows.length} row(s) look valid on this device. The server may still report other issues.',

                              style: AppTheme.body(fontSize: 12),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

              ],

              const SizedBox(height: 12),

              Expanded(

                child: Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  child: Card(

                    elevation: 0,

                    color: Colors.white.withValues(alpha: 0.88),

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(16),

                    ),

                    child: previewRows.isEmpty

                        ? Center(

                            child: Text(

                              'No rows to preview.',

                              style: AppTheme.body(color: AppTheme.textMuted),

                            ),

                          )

                        : SingleChildScrollView(

                            scrollDirection: Axis.horizontal,

                            child: SingleChildScrollView(

                              padding: const EdgeInsets.all(12),

                              child: _PreviewTable(

                                rows: previewRows,

                                issueRows: _issueRows,

                              ),

                            ),

                          ),

                  ),

                ),

              ),

              Padding(

                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

                child: FilledButton(

                  onPressed: _uploading || _hasClientErrors || _dataRows.isEmpty

                      ? null

                      : _upload,

                  style: FilledButton.styleFrom(

                    backgroundColor: AppTheme.softRose,

                    padding: const EdgeInsets.symmetric(vertical: 16),

                  ),

                  child: _uploading

                      ? const SizedBox(

                          height: 22,

                          width: 22,

                          child: CircularProgressIndicator(

                            strokeWidth: 2.5,

                            color: Colors.white,

                          ),

                        )

                      : Text(

                          _hasClientErrors

                              ? 'Fix errors to upload'

                              : 'Upload ${_dataRows.length} row(s)',

                          style: AppTheme.body(

                            fontWeight: FontWeight.w700,

                            color: Colors.white,

                          ),

                        ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _ClientIssuesBanner extends StatelessWidget {

  const _ClientIssuesBanner({required this.issues});



  final List<CustomerImportValidationIssue> issues;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Material(

        color: Colors.red.shade50,

        borderRadius: BorderRadius.circular(14),

        child: Padding(

          padding: const EdgeInsets.all(14),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                children: [

                  Icon(Icons.error_outline, color: Colors.red.shade700),

                  const SizedBox(width: 8),

                  Text(

                    '${issues.length} issue(s) found before upload',

                    style: AppTheme.body(

                      fontWeight: FontWeight.w700,

                      color: Colors.red.shade900,

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 10),

              ...issues.take(8).map(

                    (issue) => Padding(

                      padding: const EdgeInsets.only(bottom: 6),

                      child: Text(

                        issue.rowNumber > 0

                            ? 'Row ${issue.rowNumber} · ${issue.field}: ${issue.message}'

                            : '${issue.field}: ${issue.message}',

                        style: AppTheme.body(

                          fontSize: 12,

                          color: Colors.red.shade900,

                        ),

                      ),

                    ),

                  ),

              if (issues.length > 8)

                Text(

                  '…and ${issues.length - 8} more',

                  style: AppTheme.body(

                    fontSize: 12,

                    color: Colors.red.shade800,

                  ),

                ),

            ],

          ),

        ),

      ),

    );

  }

}



class _PreviewTable extends StatelessWidget {

  const _PreviewTable({

    required this.rows,

    required this.issueRows,

  });



  final List<ExcelDataRow> rows;

  final Set<int> issueRows;



  @override

  Widget build(BuildContext context) {

    final columnCount = rows.fold<int>(

      0,

      (max, row) => row.cells.length > max ? row.cells.length : max,

    );



    return Table(

      border: TableBorder.all(color: AppTheme.mintGray.withValues(alpha: 0.6)),

      defaultColumnWidth: const FixedColumnWidth(120),

      children: rows.map((row) {

        final hasIssue = issueRows.contains(row.rowNumber);

        final bg = hasIssue

            ? Colors.red.shade50

            : row.rowNumber == 1

                ? AppTheme.peach.withValues(alpha: 0.25)

                : null;

        final cells = List<String>.from(row.cells);

        while (cells.length < columnCount) {

          cells.add('');

        }

        return TableRow(

          decoration: bg != null ? BoxDecoration(color: bg) : null,

          children: [

            Padding(

              padding: const EdgeInsets.all(6),

              child: Text(

                '${row.rowNumber}',

                style: AppTheme.body(

                  fontSize: 11,

                  fontWeight: FontWeight.w700,

                  color: hasIssue ? Colors.red.shade800 : AppTheme.textMuted,

                ),

              ),

            ),

            ...cells.map(

              (text) => Padding(

                padding: const EdgeInsets.all(6),

                child: Text(

                  text,

                  style: AppTheme.body(

                    fontSize: 11,

                    color: hasIssue ? Colors.red.shade900 : AppTheme.textPrimary,

                  ),

                ),

              ),

            ),

          ],

        );

      }).toList(),

    );

  }

}


