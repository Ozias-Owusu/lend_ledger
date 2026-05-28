import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lend_ledger/core/network/api_client.dart';

class DailyLoansApiService {
  DailyLoansApiService(this._apiClient);

  final ApiClient _apiClient;

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

    debugPrint('POST /api/DailyLoans');
    debugPrint('Daily loan payload: $jsonBody');

    final response = await _apiClient.post('/api/DailyLoans', body: body);
    debugPrint('Daily loan response status: ${response.statusCode}');
    debugPrint('Daily loan response body: ${response.body}');
  }
}
