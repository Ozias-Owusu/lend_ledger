import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lend_ledger/core/network/api_client.dart';

class SoftLoansApiService {
  SoftLoansApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> createSoftLoan({
    required String customerId,
    required double principalAmount,
    required double interestRateDecimal,
    required int durationValue,
    required String durationUnit,
    required String loanStartDateIso,
    String notes = '',
  }) async {
    final body = <String, dynamic>{
      "customerId": customerId,
      "principalAmount": principalAmount,
      "interestRate": interestRateDecimal,
      "durationValue": durationValue,
      "durationUnit": durationUnit,
      "loanStartDate": loanStartDateIso,
      "notes": notes,
    };
    final jsonBody = jsonEncode(body);

    debugPrint('POST /api/SoftLoans');
    debugPrint('Soft loan payload: $jsonBody');

    final response = await _apiClient.post('/api/SoftLoans', body: body);
    debugPrint('Soft loan response status: ${response.statusCode}');
    debugPrint('Soft loan response body: ${response.body}');
  }
}
