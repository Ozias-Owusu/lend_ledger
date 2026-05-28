import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lend_ledger/core/network/api_client.dart';

class RepaymentsApiService {
  RepaymentsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    final response = await _apiClient.get(
      '/api/Repayments/transactions',
      headers: const {'accept': 'text/plain'},
    );

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected transactions response format.');
    }
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAllRepayments() async {
    final response = await _apiClient.get('/api/Repayments');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected repayments response format.');
    }
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchRepaymentsByCustomer(
    String customerId,
  ) async {
    final response = await _apiClient.get('/api/Repayments/customer/$customerId');
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

    debugPrint('POST /api/Repayments');
    debugPrint('Repayment payload: $jsonBody');

    final response = await _apiClient.post('/api/Repayments', body: body);
    debugPrint('Repayment response status: ${response.statusCode}');
    debugPrint('Repayment response body: ${response.body}');
  }
}
