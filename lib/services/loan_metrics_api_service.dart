import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lend_ledger/config/api_config.dart';
import 'package:lend_ledger/models/loan_metrics.dart';
import 'package:lend_ledger/models/loan_overview.dart';

class LoanMetricsApiService {
  Future<LoanMetrics> fetchActiveTotals() async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/LoanMetrics/active-totals'));
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch loan metrics. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format for loan metrics endpoint.');
    }

    return LoanMetrics.fromJson(decoded);
  }

  Future<LoanOverview> fetchOverview({int months = 6}) async {
    final uri = Uri.parse(
      ApiConfig.endpoint('/api/LoanMetrics/overview?months=$months'),
    );
    final response = await http.get(
      uri,
      headers: const {'accept': 'text/plain'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch overview metrics. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format for overview metrics endpoint.');
    }

    return LoanOverview.fromJson(decoded);
  }
}
