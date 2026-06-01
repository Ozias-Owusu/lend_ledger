import 'dart:convert';

/// Row-level result from bulk import APIs (Customers, Loans, Repayments).
class BulkImportRowResult {
  const BulkImportRowResult({
    required this.rowNumber,
    required this.success,
    required this.message,
    this.detail,
  });

  final int rowNumber;
  final bool success;
  final String message;

  /// Short label from nested entity (e.g. customer full name).
  final String? detail;

  factory BulkImportRowResult.fromJson(Map<String, dynamic> json) {
    return BulkImportRowResult(
      rowNumber: _asInt(_read(json, 'rowNumber', 'RowNumber'), 0),
      success: _read(json, 'success', 'Success') == true,
      message: _read(json, 'message', 'Message')?.toString() ?? '',
      detail: _extractDetail(json),
    );
  }
}

class BulkImportResult {
  const BulkImportResult({
    required this.totalRows,
    required this.successfulRows,
    required this.failedRows,
    required this.results,
  });

  final int totalRows;
  final int successfulRows;
  final int failedRows;
  final List<BulkImportRowResult> results;

  bool get hasFailures => failedRows > 0;
  bool get allFailed => totalRows > 0 && successfulRows == 0;
  bool get allSucceeded => failedRows == 0 && totalRows > 0;

  List<BulkImportRowResult> get failed =>
      results.where((r) => !r.success).toList();

  List<BulkImportRowResult> get succeeded =>
      results.where((r) => r.success).toList();

  factory BulkImportResult.fromJson(Map<String, dynamic> json) {
    final resultsRaw = _read(json, 'results', 'Results');
    final results = resultsRaw is List
        ? resultsRaw
            .whereType<Map>()
            .map((e) => BulkImportRowResult.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <BulkImportRowResult>[];

    return BulkImportResult(
      totalRows: _asInt(_read(json, 'totalRows', 'TotalRows'), results.length),
      successfulRows:
          _asInt(_read(json, 'successfulRows', 'SuccessfulRows'), 0),
      failedRows: _asInt(_read(json, 'failedRows', 'FailedRows'), 0),
      results: results,
    );
  }

  static BulkImportResult parseResponseBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected import response format.');
    }
    final map = Map<String, dynamic>.from(decoded);

    // Some endpoints return { success, data: { ... } }.
    final data = map['data'];
    if (data is Map) {
      return BulkImportResult.fromJson(Map<String, dynamic>.from(data));
    }

    return BulkImportResult.fromJson(map);
  }
}

dynamic _read(Map<String, dynamic> json, String camel, String pascal) {
  if (json.containsKey(camel)) return json[camel];
  return json[pascal];
}

int _asInt(dynamic value, int fallback) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _extractDetail(Map<String, dynamic> json) {
  for (final key in [
    'customer',
    'Customer',
    'dailyLoan',
    'DailyLoan',
    'softLoan',
    'SoftLoan',
    'repayment',
    'Repayment',
  ]) {
    final nested = json[key];
    if (nested is Map) {
      final map = Map<String, dynamic>.from(nested);
      final name = map['fullName'] ?? map['FullName'] ?? map['id'] ?? map['Id'];
      if (name != null) return name.toString();
    }
  }
  return null;
}
