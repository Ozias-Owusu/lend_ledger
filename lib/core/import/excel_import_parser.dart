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

class ExcelParseException implements Exception {
  const ExcelParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ExcelImportParser {
  static ExcelSheetData parseFile(String path, {String? fileName}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ExcelParseException('File not found.');
    }
    return parseBytes(
      file.readAsBytesSync(),
      fileName ?? path.split(Platform.pathSeparator).last,
    );
  }

  static ExcelSheetData parseBytes(List<int> bytes, String fileName) {
    if (bytes.isEmpty) {
      throw ExcelParseException('File is empty.');
    }
    final excel = Excel.decodeBytes(bytes);
    final sheetName =
        excel.tables.keys.isNotEmpty ? excel.tables.keys.first : 'Sheet1';
    final sheet = excel.tables[sheetName];
    if (sheet == null) {
      return ExcelSheetData(fileName: fileName, sheetName: sheetName, rows: []);
    }

    final rawRows = sheet.rows;
    var maxCols = 0;
    for (final row in rawRows) {
      if (row.length > maxCols) maxCols = row.length;
    }

    final rows = <ExcelDataRow>[];
    for (var i = 0; i < rawRows.length; i++) {
      final row = rawRows[i];
      final cells = List<String>.generate(maxCols, (colIndex) {
        if (colIndex >= row.length) return '';
        return _cellText(row[colIndex]);
      });
      rows.add(ExcelDataRow(rowNumber: i + 1, cells: cells));
    }

    return ExcelSheetData(fileName: fileName, sheetName: sheetName, rows: rows);
  }

  /// Data rows only (skips header row 1 and blank rows).
  static List<ExcelDataRow> dataRows(ExcelSheetData sheet) {
    return sheet.rows.where((row) {
      if (row.rowNumber <= 1) return false;
      return !row.isEmpty;
    }).toList();
  }

  static String _cellText(Data? cell) {
    if (cell == null) return '';
    final value = cell.value;
    if (value == null) return '';

    if (value is TextCellValue) {
      return value.value.toString().trim();
    }
    if (value is IntCellValue) {
      return value.value.toString();
    }
    if (value is DoubleCellValue) {
      return value.value.toString();
    }
    if (value is BoolCellValue) {
      return value.value.toString();
    }
    if (value is DateCellValue) {
      return value.asDateTimeLocal().toString();
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toString();
    }
    if (value is TimeCellValue) {
      return value.toString();
    }
    if (value is FormulaCellValue) {
      return value.formula.trim();
    }

    return value.toString().trim();
  }
}
