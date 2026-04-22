import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lend_ledger/config/api_config.dart';

class RepaymentsApiService {
  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Repayments/transactions'));
    final response = await http.get(
      uri,
      headers: const {'accept': 'text/plain'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch transactions. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected transactions response format.');
    }
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAllRepayments() async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Repayments'));
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch repayments. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected repayments response format.');
    }
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchRepaymentsByCustomer(
    String customerId,
  ) async {
    final uri = Uri.parse(
      ApiConfig.endpoint('/api/Repayments/customer/$customerId'),
    );
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch repayments. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected repayments response format.');
    }
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createRepayment({
    required String customerId,
    required String loanType,
    required String loanId,
    required double amountPaid,
    required String paymentDateIso,
    int installmentNumber = 0,
    String notes = '',
  }) async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Repayments'));
    final body = <String, dynamic>{
      "customerId": customerId,
      "loanType": loanType,
      "loanId": loanId,
      "amountPaid": amountPaid,
      "paymentDate": paymentDateIso,
      "installmentNumber": installmentNumber,
      "notes": notes,
    };
    final jsonBody = jsonEncode(body);

    debugPrint('POST $uri');
    debugPrint('Repayment payload: $jsonBody');

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonBody,
    );

    debugPrint('Repayment response status: ${response.statusCode}');
    debugPrint('Repayment response body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to create repayment. Status code: ${response.statusCode}',
      );
    }
  }
}
