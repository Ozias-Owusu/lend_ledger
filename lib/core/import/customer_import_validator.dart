import 'package:lend_ledger/core/import/excel_import_parser.dart';

class CustomerImportValidationIssue {
  const CustomerImportValidationIssue({
    required this.rowNumber,
    required this.field,
    required this.message,
  });

  final int rowNumber;
  final String field;
  final String message;
}

class CustomerImportValidator {
  static const _fullNameCol = 0;
  static const _countryCodeCol = 1;
  static const _phoneCol = 2;

  static List<CustomerImportValidationIssue> validateSheet(
    ExcelSheetData sheet,
  ) {
    final issues = <CustomerImportValidationIssue>[];
    final dataRows = ExcelImportParser.dataRows(sheet);

    if (dataRows.isEmpty) {
      issues.add(
        const CustomerImportValidationIssue(
          rowNumber: 0,
          field: 'File',
          message: 'No data rows found. Add customers below the header row.',
        ),
      );
      return issues;
    }

    for (final row in dataRows) {
      issues.addAll(_validateRow(row));
    }
    return issues;
  }

  static List<CustomerImportValidationIssue> _validateRow(ExcelDataRow row) {
    final issues = <CustomerImportValidationIssue>[];
    final cells = row.cells;
    final fullName = _cell(cells, _fullNameCol);
    final countryCode = _cell(cells, _countryCodeCol);
    final phone = _cell(cells, _phoneCol);

    if (fullName.isEmpty) {
      issues.add(
        CustomerImportValidationIssue(
          rowNumber: row.rowNumber,
          field: 'Full name',
          message: 'Full name is required.',
        ),
      );
    } else if (fullName.length < 2) {
      issues.add(
        CustomerImportValidationIssue(
          rowNumber: row.rowNumber,
          field: 'Full name',
          message: 'Full name is too short.',
        ),
      );
    }

    if (phone.isNotEmpty) {
      final digitsOnly = phone.replaceAll(RegExp(r'\s'), '');
      if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
        issues.add(
          CustomerImportValidationIssue(
            rowNumber: row.rowNumber,
            field: 'Phone number',
            message: 'Phone number must contain digits only.',
          ),
        );
      }
    }

    if (countryCode.isNotEmpty &&
        !countryCode.startsWith('+') &&
        !RegExp(r'^\d+$').hasMatch(countryCode)) {
      issues.add(
        CustomerImportValidationIssue(
          rowNumber: row.rowNumber,
          field: 'Country code',
          message: 'Use a format like +233 or leave blank for default.',
        ),
      );
    }

    return issues;
  }

  static String _cell(List<String> cells, int index) {
    if (index >= cells.length) return '';
    return cells[index].trim();
  }
}
