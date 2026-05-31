import 'package:http/http.dart' as http;
import 'package:lend_ledger/core/network/api_client.dart';
import 'package:lend_ledger/models/bulk_import_models.dart';

class BulkImportApiService {
  BulkImportApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<BulkImportResult> importFile({
    required String endpointPath,
    required String filePath,
  }) async {
    final response = await _apiClient.sendMultipart(
      path: endpointPath,
      files: [await http.MultipartFile.fromPath('file', filePath)],
    );
    final body = await response.stream.bytesToString();
    return BulkImportResult.parseResponseBody(body);
  }
}
