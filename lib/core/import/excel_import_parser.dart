import 'dart:io';

import 'package:excel/excel.dart';

class ExcelSheetData {
  const ExcelSheetData({
    required this.fileName,
    required this.sheetName,
    required this.rows,
  });

  final String fileName;
  final String sheetName;

  /// Each row: excel row number (1-based) + cell values.
  final List<ExcelDataRow> rows;
}

class ExcelDataRow {
  const ExcelDataRow({
    required this.rowNumber,
    required this.cells,
  });

  final int rowNumber;
  final List<String> cells;

  bool get isEmpty => cells.every((c) => c.trim().isEmpty);
}

class ExcelImportParser {
  static ExcelSheetData parseFile(String path) {
    final file = File(path);
    final name = path.split(Platform.pathSeparator).last;
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheetName =
        excel.tables.keys.isNotEmpty ? excel.tables.keys.first : 'Sheet1';
    final sheet = excel.tables[sheetName];
    if (sheet == null) {
      return ExcelSheetData(fileName: name, sheetName: sheetName, rows: []);
    }

    final rows = <ExcelDataRow>[];
    for (var i = 0; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final cells = row.map((c) => (c?.value ?? '').toString().trim()).toList();
      rows.add(ExcelDataRow(rowNumber: i + 1, cells: cells));
    }

    return ExcelSheetData(fileName: name, sheetName: sheetName, rows: rows);
  }

  /// Data rows only (skips header row 1 and blank rows).
  static List<ExcelDataRow> dataRows(ExcelSheetData sheet) {
    return sheet.rows.where((row) {
      if (row.rowNumber <= 1) return false;
      return !row.isEmpty;
    }).toList();
  }
}
