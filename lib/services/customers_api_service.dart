import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lend_ledger/core/network/api_client.dart';
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
  CustomersApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Customer>> fetchCustomers() async {
    final response = await _apiClient.get('/api/Customers');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format for customers endpoint.');
    }

    return decoded
        .map((item) => Customer.fromApiJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> fetchCustomerById(String customerId) async {
    final response = await _apiClient.get('/api/Customers/$customerId');
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format for customer details.');
    }

    return Customer.fromApiJson(decoded);
  }

  Future<void> deleteCustomer(String customerId) async {
    await _apiClient.delete('/api/Customers/$customerId');
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

    await _apiClient.post('/api/Customers', body: body);
  }

  Future<CustomersImportTemplate> downloadImportTemplate() async {
    return downloadImportTemplateByPath('/api/Customers/import-template');
  }

  Future<CustomersImportTemplate> downloadImportTemplateByPath(
    String endpointPath,
  ) async {
    final response = await _apiClient.get(endpointPath);
    final contentDisposition = response.headers['content-disposition'] ?? '';
    final filename = _parseFilenameFromContentDisposition(contentDisposition);

    return CustomersImportTemplate(
      filename: filename,
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'] ?? '',
    );
  }

  Future<void> importCustomersFile(String filePath) async {
    return importFileByPath(endpointPath: '/api/Customers/import', filePath: filePath);
  }

  Future<void> importFileByPath({
    required String endpointPath,
    required String filePath,
  }) async {
    await _apiClient.sendMultipart(
      path: endpointPath,
      files: [await http.MultipartFile.fromPath('file', filePath)],
    );
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
      "customer": fullName,
    };
    final jsonBody = jsonEncode(body);

    debugPrint('PUT /api/Customers/$id');
    debugPrint('Update customer payload: $jsonBody');

    final response = await _apiClient.put('/api/Customers/$id', body: body);
    debugPrint('Update customer response status: ${response.statusCode}');
    debugPrint('Update customer response body: ${response.body}');
  }

  String? _asBase64OrRaw(String? value) {
    if (value == null || value.isEmpty) return null;
    final file = File(value);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      return base64Encode(bytes);
    }
    return value;
  }

  int? _toNullableInt32(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    final local = digits.length > 9
        ? digits.substring(digits.length - 9)
        : digits;
    return int.tryParse(local);
  }
}

String _parseFilenameFromContentDisposition(String header) {
  const fallback = 'customers-import-template.xlsx';
  if (header.isEmpty) return fallback;

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
