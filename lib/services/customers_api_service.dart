import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lend_ledger/config/api_config.dart';
import 'package:lend_ledger/models/customer.dart';

class CustomersApiService {
  Future<List<Customer>> fetchCustomers() async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Customers'));
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch customers. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format for customers endpoint.');
    }

    return decoded
        .map((item) => Customer.fromApiJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> fetchCustomerById(String customerId) async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Customers/$customerId'));
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch customer details. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format for customer details.');
    }

    return Customer.fromApiJson(decoded);
  }

  Future<void> deleteCustomer(String customerId) async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Customers/$customerId'));
    final response = await http.delete(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to delete customer. Status code: ${response.statusCode}',
      );
    }
  }

  Future<void> createCustomer({
    required String fullName,
    required String countryCode,
    required String phoneNumber,
    String? ghanaCardNumber,
    String? licenseIdNumber,
    String? ghanaCardImagePath,
    String? licenseIdImagePath,
    String? profilePicturePath,
  }) async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Customers'));
    final body = <String, dynamic>{
      "fullName": fullName,
      "countryCode": countryCode,
      "phoneNumber": int.tryParse(phoneNumber) ?? 0,
      "ghanaCardNumber": ghanaCardNumber ?? "",
      "licenseIdNumber": licenseIdNumber ?? "",
      "ghanaCardImage": _asBase64OrRaw(ghanaCardImagePath),
      "licenseIdImage": _asBase64OrRaw(licenseIdImagePath),
      "profilePicture": _asBase64OrRaw(profilePicturePath),
    };

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to create customer. Status code: ${response.statusCode}',
      );
    }
  }

  Future<void> updateCustomer({
    required String id,
    required String fullName,
    required String countryCode,
    required String phoneNumber,
    String? ghanaCardNumber,
    String? licenseIdNumber,
    String? ghanaCardImagePath,
    String? licenseIdImagePath,
    String? profilePicturePath,
    List<Map<String, dynamic>> dailyLoans = const [],
    List<Map<String, dynamic>> softLoans = const [],
  }) async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Customers/$id'));
    final normalizedPhone = _toNullableInt32(phoneNumber);
    final body = <String, dynamic>{
      "id": id,
      "fullName": fullName,
      "countryCode": countryCode,
      "phoneNumber": normalizedPhone,
      "ghanaCardNumber": ghanaCardNumber ?? "",
      "licenseIdNumber": licenseIdNumber ?? "",
      "ghanaCardImage": _asBase64OrRaw(ghanaCardImagePath),
      "licenseIdImage": _asBase64OrRaw(licenseIdImagePath),
      "profilePicture": _asBase64OrRaw(profilePicturePath),
      // Required by backend model binding on update.
      "customer": fullName,
    };
    final jsonBody = jsonEncode(body);

    debugPrint('PUT $uri');
    debugPrint('Update customer payload: $jsonBody');

    final response = await http.put(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonBody,
    );

    debugPrint('Update customer response status: ${response.statusCode}');
    debugPrint('Update customer response body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to update customer. Status code: ${response.statusCode}. Response: ${response.body}',
      );
    }
  }

  String? _asBase64OrRaw(String? value) {
    if (value == null || value.isEmpty) return null;
    final file = File(value);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      return base64Encode(bytes);
    }
    // Already a base64 string from API response.
    return value;
  }

  int? _toNullableInt32(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    // phoneNumber backend expects Int32; keep a safe local-number-sized value.
    final local = digits.length > 9
        ? digits.substring(digits.length - 9)
        : digits;
    return int.tryParse(local);
  }
}
