import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lend_ledger/config/api_config.dart';

class DailyLoansApiService {
  Future<void> createDailyLoan({
    required String id,
    required String customerId,
    required double principalAmount,
    required double interestRateDecimal,
    required double interestAmount,
    required double totalRepayableAmount,
    required String loanDateIso,
    required String dueDateIso,
    required String status,
    String notes = '',
  }) async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/DailyLoans'));
    final body = <String, dynamic>{
      "id": id,
      "customerId": customerId,
      "principalAmount": principalAmount,
      "interestRate": interestRateDecimal,
      "interestAmount": interestAmount,
      "totalRepayableAmount": totalRepayableAmount,
      "loanDate": loanDateIso,
      "dueDate": dueDateIso,
      "status": status,
      "notes": notes,
    };
    final jsonBody = jsonEncode(body);

    debugPrint('POST $uri');
    debugPrint('Daily loan payload: $jsonBody');

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonBody,
    );

    debugPrint('Daily loan response status: ${response.statusCode}');
    debugPrint('Daily loan response body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to create daily loan. Status code: ${response.statusCode}',
      );
    }
  }
}
