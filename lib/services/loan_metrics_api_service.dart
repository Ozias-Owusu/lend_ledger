import 'dart:convert';

import 'package:lend_ledger/core/network/api_client.dart';
import 'package:lend_ledger/models/loan_metrics.dart';
import 'package:lend_ledger/models/loan_overview.dart';

class LoanMetricsApiService {
  LoanMetricsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<LoanMetrics> fetchActiveTotals() async {
    final response = await _apiClient.get('/api/LoanMetrics/active-totals');
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format for loan metrics endpoint.');
    }

    return LoanMetrics.fromJson(decoded);
  }

  Future<LoanOverview> fetchOverview({int months = 6}) async {
    final response = await _apiClient.get(
      '/api/LoanMetrics/overview?months=$months',
      headers: const {'accept': 'text/plain'},
    );

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format for overview metrics endpoint.');
    }

    return LoanOverview.fromJson(decoded);
  }
}
