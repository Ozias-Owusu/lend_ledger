import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lend_ledger/config/api_config.dart';

class SoftLoansApiService {
  Future<void> createSoftLoan({
    required String customerId,
    required double principalAmount,
    required double interestRateDecimal,
    required int durationValue,
    required String durationUnit,
    required String loanStartDateIso,
    String notes = '',
  }) async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/SoftLoans'));
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

    debugPrint('POST $uri');
    debugPrint('Soft loan payload: $jsonBody');

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonBody,
    );

    debugPrint('Soft loan response status: ${response.statusCode}');
    debugPrint('Soft loan response body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to create soft loan. Status code: ${response.statusCode}',
      );
    }
  }
}
