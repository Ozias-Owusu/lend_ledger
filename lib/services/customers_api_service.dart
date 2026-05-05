import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lend_ledger/config/api_config.dart';
import 'package:lend_ledger/models/customer.dart';

class CustomersImportTemplate {
  const CustomersImportTemplate({
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String filename;
  final List<int> bytes;
  final String contentType;
}

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

  Future<CustomersImportTemplate> downloadImportTemplate() async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Customers/import-template'));
    final response = await http.get(uri, headers: const {'accept': '*/*'});

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to download import template. Status code: ${response.statusCode}',
      );
    }

    final contentDisposition = response.headers['content-disposition'] ?? '';
    final filename = _parseFilenameFromContentDisposition(contentDisposition);

    return CustomersImportTemplate(
      filename: filename,
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'] ?? '',
    );
  }

  Future<void> importCustomersFile(String filePath) async {
    final uri = Uri.parse(ApiConfig.endpoint('/api/Customers/import'));
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(
        'Failed to import customers. Status code: ${streamed.statusCode}. Response: $body',
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

String _parseFilenameFromContentDisposition(String header) {
  const fallback = 'customers-import-template.xlsx';
  if (header.isEmpty) return fallback;

  // RFC 5987: filename*=UTF-8''encoded-name
  final rfc5987 = RegExp(
    r"filename\*\s*=\s*UTF-8''([^;\r\n]+)",
    caseSensitive: false,
  );
  final mStar = rfc5987.firstMatch(header);
  if (mStar != null) {
    final name = mStar.group(1)?.trim().replaceAll('"', '');
    if (name != null && name.isNotEmpty) {
      return Uri.decodeFull(name);
    }
  }

  final simple = RegExp(
    r'filename\s*=\s*"?([^";\r\n]+)"?',
    caseSensitive: false,
  );
  final m = simple.firstMatch(header);
  if (m != null) {
    final name = m.group(1)?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
  }

  return fallback;
}
