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
      rowNumber: _asInt(json['rowNumber'], 0),
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
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
    final resultsRaw = json['results'];
    final results = resultsRaw is List
        ? resultsRaw
            .whereType<Map>()
            .map((e) => BulkImportRowResult.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <BulkImportRowResult>[];

    return BulkImportResult(
      totalRows: _asInt(json['totalRows'], results.length),
      successfulRows: _asInt(json['successfulRows'], 0),
      failedRows: _asInt(json['failedRows'], 0),
      results: results,
    );
  }

  static BulkImportResult parseResponseBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected import response format.');
    }
    return BulkImportResult.fromJson(Map<String, dynamic>.from(decoded));
  }
}

int _asInt(dynamic value, int fallback) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _extractDetail(Map<String, dynamic> json) {
  for (final key in ['customer', 'dailyLoan', 'softLoan', 'repayment']) {
    final nested = json[key];
    if (nested is Map) {
      final name = nested['fullName'] ?? nested['id'];
      if (name != null) return name.toString();
    }
  }
  return null;
}
