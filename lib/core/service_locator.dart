import 'package:lend_ledger/core/auth/token_storage_service.dart';
import 'package:lend_ledger/core/network/api_client.dart';
import 'package:lend_ledger/services/auth_api_service.dart';
import 'package:lend_ledger/services/customers_api_service.dart';
import 'package:lend_ledger/services/daily_loans_api_service.dart';
import 'package:lend_ledger/services/loan_metrics_api_service.dart';
import 'package:lend_ledger/services/repayments_api_service.dart';
import 'package:lend_ledger/services/soft_loans_api_service.dart';

/// Central dependency wiring for API/auth services.
class ServiceLocator {
  ServiceLocator._();

  static final TokenStorageService tokenStorage = TokenStorageService();
  static late final ApiClient apiClient;
  static late final AuthApiService authApi;
  static late final CustomersApiService customersApi;
  static late final LoanMetricsApiService loanMetricsApi;
  static late final RepaymentsApiService repaymentsApi;
  static late final DailyLoansApiService dailyLoansApi;
  static late final SoftLoansApiService softLoansApi;

  static void init({SessionExpiredCallback? onSessionExpired}) {
    apiClient = ApiClient(
      tokenStorage: tokenStorage,
      onSessionExpired: onSessionExpired,
    );
    authApi = AuthApiService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
    customersApi = CustomersApiService(apiClient);
    loanMetricsApi = LoanMetricsApiService(apiClient);
    repaymentsApi = RepaymentsApiService(apiClient);
    dailyLoansApi = DailyLoansApiService(apiClient);
    softLoansApi = SoftLoansApiService(apiClient);
  }
}
