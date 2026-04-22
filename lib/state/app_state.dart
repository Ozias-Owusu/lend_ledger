// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:lend_ledger/db/customers_dao.dart';
// import 'package:lend_ledger/db/transaction_dao.dart';
// import 'package:lend_ledger/models/customer.dart';
// import 'package:lend_ledger/models/loan_record.dart';
// import 'package:lend_ledger/models/transactionRecord.dart';
// import 'package:uuid/uuid.dart';
// import 'package:local_auth/local_auth.dart';
//
// final _uuid = Uuid();
//
// class AppState extends ChangeNotifier {
//   // --- DAOs are the single source of truth for DB interaction ---
//   final CustomersDao _customersDao = CustomersDao();
//   final TransactionsDao _transactionsDao = TransactionsDao();
//
//   // --- In-memory cache of the database state ---
//   List<Customer> customers = [];
//   List<TransactionRecord> transactions = [];
//   bool isLoggedIn = false;
//   String loggedInEmail = '';
//   String loggedInUserName = '';
//   final LocalAuthentication auth =
//       LocalAuthentication(); // <-- Add this instance
//
//   Future<bool> areBiometricsEnabled() async {
//     final sp = await SharedPreferences.getInstance();
//     return sp.getBool('biometricsEnabled') ?? false;
//   }
//
//   // --- New method to perform biometric login ---
//   Future<bool> biometricLogin() async {
//     try {
//       final didAuthenticate = await auth.authenticate(
//         localizedReason: 'Please authenticate to log in',
//         biometricOnly: true,
//       );
//
//       if (didAuthenticate) {
//         // If successful, load the user's details from SharedPreferences
//         final sp = await SharedPreferences.getInstance();
//         loggedInEmail = sp.getString('registered_email') ?? '';
//         loggedInUserName = sp.getString('registered_name') ?? '';
//         isLoggedIn = true;
//
//         // Persist the session
//         await sp.setBool('isLoggedIn', true);
//         await sp.setString('loggedInEmail', loggedInEmail);
//         await sp.setString('loggedInUserName', loggedInUserName);
//
//         notifyListeners();
//         return true;
//       }
//       return false;
//     } catch (e) {
//       print("Biometric login error: $e");
//       return false;
//     }
//   }
//
//   // --- Core Data Loading and Auth State ---
//   Future<void> loadFromDb() async {
//     // 1. Load business data from SQLite
//     customers = await _customersDao.getAllCustomers();
//     transactions = await _transactionsDao.getAllTransactions();
//
//     // 2. Load auth state from SharedPreferences
//     final sp = await SharedPreferences.getInstance();
//     isLoggedIn = sp.getBool('isLoggedIn') ?? false;
//     loggedInEmail = sp.getString('loggedInEmail') ?? '';
//     loggedInUserName = sp.getString('loggedInUserName') ?? '';
//
//     // 3. Notify UI
//     notifyListeners();
//   }
//
//   // --- Authentication with SharedPreferences ---
//
//   Future<bool> signUp({
//     required String name,
//     required String email,
//     required String password,
//   }) async {
//     if (name.isEmpty || email.isEmpty || password.length < 6) {
//       return false;
//     }
//     final sp = await SharedPreferences.getInstance();
//     // Save the new user's credentials
//     await sp.setString('registered_email', email);
//     await sp.setString('registered_password', password);
//     await sp.setString('registered_name', name);
//
//     // Automatically log them in
//     isLoggedIn = true;
//     loggedInEmail = email;
//     loggedInUserName = name;
//     await sp.setBool('isLoggedIn', true);
//     await sp.setString('loggedInEmail', email);
//
//     notifyListeners();
//     return true;
//   }
//
//   Future<bool> login(String email, String password) async {
//     final sp = await SharedPreferences.getInstance();
//
//     // Get the saved credentials
//     final registeredEmail = sp.getString('registered_email');
//     final registeredPassword = sp.getString('registered_password');
//     final registeredName = sp.getString('registered_name') ?? '';
//
//     // Check if the provided credentials match the saved ones
//     if (email.isNotEmpty &&
//         password.isNotEmpty &&
//         email == registeredEmail &&
//         password == registeredPassword) {
//       // If they match, update the login state
//       isLoggedIn = true;
//       loggedInEmail = email;
//       loggedInUserName = registeredName;
//       await sp.setBool('isLoggedIn', true);
//       await sp.setString('loggedInEmail', email);
//
//       notifyListeners();
//       return true;
//     }
//
//     // If they don't match, return false
//     return false;
//   }
//
//   Future<void> setAppPin(String pin) async {
//     if (pin.length != 6) return; // Ensure it's a 6-digit PIN
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString('app_pin', pin); // In a real app, hash this!
//   }
//
//   // You can also add a method to verify the pin later
//   Future<bool> verifyAppPin(String pin) async {
//     final sp = await SharedPreferences.getInstance();
//     final savedPin = sp.getString('app_pin');
//     return savedPin == pin;
//   }
//
//   Future<void> logout() async {
//     final sp = await SharedPreferences.getInstance();
//     // Clear the session state
//     isLoggedIn = false;
//     loggedInEmail = '';
//     loggedInUserName = '';
//     await sp.setBool('isLoggedIn', false);
//     await sp.setString('loggedInEmail', '');
//
//     notifyListeners();
//   }
//
//   // --- Customer Operations (DB Only) ---
//   Future<void> addCustomer({
//     required String name,
//     required String phone,
//     required String vehicle,
//     String? ghanaCardNumber,
//     String? licenseIdNumber,
//     required String dateJoined,
//     String? loanType,
//     String? ghanaCardFrontImage,
//     String? ghanaCardBackImage,
//     String? licenseFrontImage,
//     String? licenseBackImage,
//   }) async {
//     final newCustomer = Customer(
//       id: _uuid.v4(),
//       name: name,
//       phone: phone,
//       ghanaCardNumber: ghanaCardNumber ?? '',
//       licenseIdNumber: licenseIdNumber ?? '',
//       dateJoined: dateJoined,
//       loanType: loanType,
//       ghanaCardFrontImage: ghanaCardFrontImage,
//       ghanaCardBackImage: ghanaCardBackImage,
//       licenseFrontImage: licenseFrontImage,
//       licenseBackImage: licenseBackImage,
//     );
//     await _customersDao.insertCustomer(newCustomer);
//     await loadFromDb();
//   }
//
//   Future<void> updateCustomer({
//     required String id,
//     required String name,
//     required String phone,
//     required String vehicle,
//     String? ghanaCardNumber,
//     String? licenseIdNumber,
//     required String dateJoined,
//     String? loanType,
//     String? ghanaCardFrontImage,
//     String? ghanaCardBackImage,
//     String? licenseFrontImage,
//     String? licenseBackImage,
//   }) async {
//     final updatedCustomer = Customer(
//       id: id,
//       name: name,
//       phone: phone,
//       ghanaCardNumber: ghanaCardNumber ?? '',
//       licenseIdNumber: licenseIdNumber ?? '',
//       dateJoined: dateJoined,
//       loanType: loanType,
//       ghanaCardFrontImage: ghanaCardFrontImage,
//       ghanaCardBackImage: ghanaCardBackImage,
//       licenseFrontImage: licenseFrontImage,
//       licenseBackImage: licenseBackImage,
//     );
//     await _customersDao.updateCustomer(updatedCustomer);
//     await loadFromDb();
//   }
//
//   Future<void> deleteCustomer(String customerId) async {
//     await _customersDao.deleteCustomer(customerId);
//     await loadFromDb();
//   }
//
//   String generateUUID() {
//     return _uuid.v4();
//   }
//
//   // --- Transaction Operations (DB Only) ---
//   Future<void> addTransaction({
//     required String id,
//     required String customerId,
//     required TransactionType type,
//     required String loanKind,
//     required double amount,
//     double interestPercent = 0.0,
//     required String date,
//     String note = '',
//   }) async {
//     final newTransaction = TransactionRecord(
//       id: id,
//       customerId: customerId,
//       type: type,
//       loanKind: loanKind,
//       amount: amount,
//       interestPercent: interestPercent,
//       date: date,
//       note: note,
//     );
//     await _transactionsDao.insertTransaction(newTransaction);
//     await loadFromDb();
//   }
//
//   // --- Getter and Calculation Methods (operate on in-memory lists) ---
//
//   List<TransactionRecord> transactionsForCustomer(String customerId) {
//     final list = transactions.where((t) => t.customerId == customerId).toList();
//     list.sort((a, b) => b.date.compareTo(a.date));
//     return list;
//   }
//
//   // In C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/state/app_state.dart
//
//   List<LoanRecord> getCustomerLoans(String customerId) {
//     final customerTransactions = transactionsForCustomer(customerId);
//
//     // 1. Separate loans and repayments into two lists
//     final loans = customerTransactions.where((t) => t.type == TransactionType.loan).toList();
//     final repayments = customerTransactions.where((t) => t.type == TransactionType.repayment).toList();
//
//     // 2. Create a map to store total repayments for each specific loan ID
//     final Map<String, double> repaymentsByLoanId = {};
//     for (final repayment in repayments) {
//       // Extract the loan ID from the note, e.g., "Repayment for loan: [ID]"
//       final noteParts = repayment.note.split(':');
//       if (noteParts.length == 2) {
//         final loanId = noteParts[1].trim();
//         // Add the repayment amount to the total for that loan ID
//         repaymentsByLoanId[loanId] = (repaymentsByLoanId[loanId] ?? 0) + repayment.amount;
//       }
//     }
//
//     // 3. Create the final list of active loans
//     final List<LoanRecord> activeLoans = [];
//
//     for (final loan in loans) {
//       final totalOwedForThisLoan = loan.amount; // This is already principal + interest
//       final totalRepaidForThisLoan = repaymentsByLoanId[loan.id] ?? 0.0;
//
//       final remainingBalance = totalOwedForThisLoan - totalRepaidForThisLoan;
//
//       // 4. If there's still a balance on this loan, it's active.
//       if (remainingBalance > 0.01) { // Use an epsilon for floating point issues
//         activeLoans.add(LoanRecord.fromTransaction(loan, remainingBalance));
//       }
//     }
//
//     // 5. Return the list of active loans, showing newest first.
//     return activeLoans;
//   }
//
//
//   // List<LoanRecord> getCustomerLoans(String customerId) {
//   //   final customerTransactions = transactionsForCustomer(customerId);
//   //   final totalRepaid = customerTransactions
//   //       .where((t) => t.type == TransactionType.repayment)
//   //       .fold(0.0, (sum, t) => sum + t.amount);
//   //   final loans = customerTransactions
//   //       .where((t) => t.type == TransactionType.loan)
//   //       .toList();
//   //   final List<LoanRecord> activeLoans = [];
//   //   double repaymentsApplied = 0;
//   //   for (final loan in loans.reversed) {
//   //     final totalOwedForThisLoan = loan.amount;
//   //     final applicableRepayment = (totalRepaid - repaymentsApplied).clamp(
//   //       0.0,
//   //       totalOwedForThisLoan,
//   //     );
//   //     final remainingBalance = totalOwedForThisLoan - applicableRepayment;
//   //     repaymentsApplied += applicableRepayment;
//   //     if (remainingBalance > 0.01) {
//   //       activeLoans.add(LoanRecord.fromTransaction(loan, remainingBalance));
//   //     }
//   //   }
//   //   return activeLoans.reversed.toList();
//   // }
//
//   double computeBalance(String customerId) {
//     double balance = 0.0;
//     for (final t in transactionsForCustomer(customerId)) {
//       if (t.type == TransactionType.loan) {
//         balance += t.amount;
//       } else {
//         balance -= t.amount;
//       }
//     }
//     return balance > 0 ? balance : 0.0; // Ensure balance doesn't go negative
//   }
//
//   double totalBorrowed(String customerId) {
//     return transactionsForCustomer(customerId)
//         .where((t) => t.type == TransactionType.loan)
//         .fold(0.0, (sum, t) => sum + t.amount);
//   }
//
//   double totalRepaid(String customerId) {
//     return transactionsForCustomer(customerId)
//         .where((t) => t.type == TransactionType.repayment)
//         .fold(0.0, (sum, t) => sum + t.amount);
//   }
//
//   double getLoansToday() {
//     final today = DateTime.now();
//     final todayDate =
//         "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
//     return transactions
//         .where(
//           (t) => t.type == TransactionType.loan && t.date.startsWith(todayDate),
//         )
//         .fold(0.0, (sum, t) => sum + t.amount);
//   }
//
//   int getActiveLoanCount() {
//     int count = 0;
//     for (final customer in customers) {
//       count += getCustomerLoans(customer.id).length;
//     }
//     return count;
//   }
//
//   int totalCustomers() => customers.length;
//
//   double totalOutstanding() {
//     return customers.fold(0.0, (sum, c) => sum + computeBalance(c.id));
//   }
// }

import 'package:flutter/foundation.dart';
import 'package:lend_ledger/db/soft_loan_dao.dart';
import 'package:lend_ledger/models/installment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lend_ledger/db/customers_dao.dart';
import 'package:lend_ledger/db/transaction_dao.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/loan_record.dart';
import 'package:lend_ledger/models/loan_metrics.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:lend_ledger/services/customers_api_service.dart';
import 'package:lend_ledger/services/loan_metrics_api_service.dart';
import 'package:uuid/uuid.dart';
import 'package:local_auth/local_auth.dart';

final _uuid = Uuid();

class AppState extends ChangeNotifier {
  // --- DAOs ---
  final CustomersDao _customersDao = CustomersDao();
  final TransactionsDao _transactionsDao = TransactionsDao();
  final SoftLoanDao _softLoanDao = SoftLoanDao();
  final CustomersApiService _customersApiService = CustomersApiService();
  final LoanMetricsApiService _loanMetricsApiService = LoanMetricsApiService();
  final LocalAuthentication auth = LocalAuthentication();

  // --- In-memory state ---
  List<Customer> customers = [];
  List<Customer> apiCustomers = [];
  String? customersApiError;
  LoanMetrics? dashboardMetrics;
  String? dashboardMetricsError;
  List<TransactionRecord> transactions = [];
  bool isLoggedIn = false;
  String loggedInEmail = '';
  String loggedInUserName = '';

  // --- Core Data Loading ---
  Future<void> loadFromDb() async {
    customers = await _customersDao.getAllCustomers();
    transactions = await _transactionsDao.getAllTransactions();
    final sp = await SharedPreferences.getInstance();
    isLoggedIn = sp.getBool('isLoggedIn') ?? false;
    loggedInEmail = sp.getString('loggedInEmail') ?? '';
    loggedInUserName = sp.getString('loggedInUserName') ?? '';
    notifyListeners();
  }

  Future<void> loadCustomersFromApi() async {
    customersApiError = null;
    try {
      apiCustomers = await _customersApiService.fetchCustomers();
    } catch (e) {
      customersApiError = e.toString();
      apiCustomers = [];
    }
    notifyListeners();
  }

  Future<void> loadDashboardMetricsFromApi() async {
    dashboardMetricsError = null;
    try {
      dashboardMetrics = await _loanMetricsApiService.fetchActiveTotals();
    } catch (e) {
      dashboardMetricsError = e.toString();
      dashboardMetrics = null;
    }
    notifyListeners();
  }

  Future<Customer> fetchCustomerDetailsFromApi(String customerId) async {
    return _customersApiService.fetchCustomerById(customerId);
  }

  Future<void> deleteCustomerFromApi(String customerId) async {
    customersApiError = null;
    await _customersApiService.deleteCustomer(customerId);
    apiCustomers.removeWhere((customer) => customer.id == customerId);
    notifyListeners();
  }

  Future<void> addCustomerToApi({
    required String fullName,
    required String countryCode,
    required String phoneNumber,
    String? ghanaCardNumber,
    String? licenseIdNumber,
    String? ghanaCardImagePath,
    String? licenseIdImagePath,
    String? profilePicturePath,
  }) async {
    customersApiError = null;
    await _customersApiService.createCustomer(
      fullName: fullName,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      ghanaCardNumber: ghanaCardNumber,
      licenseIdNumber: licenseIdNumber,
      ghanaCardImagePath: ghanaCardImagePath,
      licenseIdImagePath: licenseIdImagePath,
      profilePicturePath: profilePicturePath,
    );
    await loadCustomersFromApi();
  }

  Future<void> updateCustomerInApi({
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
    customersApiError = null;
    await _customersApiService.updateCustomer(
      id: id,
      fullName: fullName,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      ghanaCardNumber: ghanaCardNumber,
      licenseIdNumber: licenseIdNumber,
      ghanaCardImagePath: ghanaCardImagePath,
      licenseIdImagePath: licenseIdImagePath,
      profilePicturePath: profilePicturePath,
      dailyLoans: dailyLoans,
      softLoans: softLoans,
    );
    await loadCustomersFromApi();
  }

  String generateUUID() => _uuid.v4();

  // --- Authentication ---
  // (Your existing login, signUp, logout, etc. methods remain here)
  Future<bool> areBiometricsEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('biometricsEnabled') ?? false;
  }

  Future<bool> biometricLogin() async {
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to log in',
        // options: const AuthOptions(
        //   biometricOnly: true,
        //   stickyAuth: true,
        // ),
        biometricOnly: true,
      );
      if (didAuthenticate) {
        final sp = await SharedPreferences.getInstance();
        loggedInEmail = sp.getString('registered_email') ?? '';
        loggedInUserName = sp.getString('registered_name') ?? '';
        isLoggedIn = true;
        await sp.setBool('isLoggedIn', true);
        await sp.setString('loggedInEmail', loggedInEmail);
        await sp.setString('loggedInUserName', loggedInUserName);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print("Biometric login error: $e");
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.isEmpty || email.isEmpty || password.length < 6) return false;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('registered_email', email);
    await sp.setString('registered_password', password);
    await sp.setString('registered_name', name);
    isLoggedIn = true;
    loggedInEmail = email;
    loggedInUserName = name;
    await sp.setBool('isLoggedIn', true);
    await sp.setString('loggedInEmail', email);
    await sp.setString('loggedInUserName', name);
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    final sp = await SharedPreferences.getInstance();
    final registeredEmail = sp.getString('registered_email');
    final registeredPassword = sp.getString('registered_password');
    final registeredName = sp.getString('registered_name') ?? '';
    if (email.isNotEmpty &&
        password.isNotEmpty &&
        email == registeredEmail &&
        password == registeredPassword) {
      isLoggedIn = true;
      loggedInEmail = email;
      loggedInUserName = registeredName;
      await sp.setBool('isLoggedIn', true);
      await sp.setString('loggedInEmail', email);
      await sp.setString('loggedInUserName', registeredName);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    isLoggedIn = false;
    loggedInEmail = '';
    loggedInUserName = '';
    await sp.setBool('isLoggedIn', false);
    await sp.setString('loggedInEmail', '');
    await sp.setString('loggedInUserName', '');
    notifyListeners();
  }

  // --- Customer & Transaction Operations ---
  // (addCustomer, updateCustomer, deleteCustomer, addTransaction remain the same)
  Future<void> addCustomer({
    required String name,
    required String phone,
    required String vehicle,
    String? ghanaCardNumber,
    String? licenseIdNumber,
    required String dateJoined,
    String? loanType,
    String? ghanaCardFrontImage,
    String? ghanaCardBackImage,
    String? licenseFrontImage,
    String? licenseBackImage,
  }) async {
    final newCustomer = Customer(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      ghanaCardNumber: ghanaCardNumber ?? '',
      licenseIdNumber: licenseIdNumber ?? '',
      dateJoined: dateJoined,
      loanType: loanType,
      ghanaCardFrontImage: ghanaCardFrontImage,
      ghanaCardBackImage: ghanaCardBackImage,
      licenseFrontImage: licenseFrontImage,
      licenseBackImage: licenseBackImage,
    );
    await _customersDao.insertCustomer(newCustomer);
    await loadFromDb();
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    required String phone,
    required String vehicle,
    String? ghanaCardNumber,
    String? licenseIdNumber,
    required String dateJoined,
    String? loanType,
    String? ghanaCardFrontImage,
    String? ghanaCardBackImage,
    String? licenseFrontImage,
    String? licenseBackImage,
  }) async {
    final updatedCustomer = Customer(
      id: id,
      name: name,
      phone: phone,
      ghanaCardNumber: ghanaCardNumber ?? '',
      licenseIdNumber: licenseIdNumber ?? '',
      dateJoined: dateJoined,
      loanType: loanType,
      ghanaCardFrontImage: ghanaCardFrontImage,
      ghanaCardBackImage: ghanaCardBackImage,
      licenseFrontImage: licenseFrontImage,
      licenseBackImage: licenseBackImage,
    );
    await _customersDao.updateCustomer(updatedCustomer);
    await loadFromDb();
  }

  Future<void> deleteCustomer(String customerId) async {
    await _customersDao.deleteCustomer(customerId);
    await loadFromDb();
  }

  Future<void> addTransaction({
    required String id,
    required String customerId,
    required TransactionType type,
    required String loanKind,
    required double amount,
    double interestPercent = 0.0,
    required String date,
    String note = '',
  }) async {
    final newTransaction = TransactionRecord(
      id: id,
      customerId: customerId,
      type: type,
      loanKind: loanKind,
      amount: amount,
      interestPercent: interestPercent,
      date: date,
      note: note,
    );
    await _transactionsDao.insertTransaction(newTransaction);
    await loadFromDb();
  }

  // --- Loan & Installment Logic ---
  Future<List<Installment>> getInstallmentsForLoan(LoanRecord loan) async {
    if (loan.loanKind != 'soft') return [];
    final details = await _softLoanDao.getSoftLoanDetails(loan.id);
    if (details == null) return [];

    final customerTransactions = await _transactionsDao
        .getTransactionsForCustomer(loan.customerId);
    final repaymentsForThisLoan = customerTransactions
        .where(
          (t) =>
              t.type == TransactionType.repayment && t.note.contains(loan.id),
        )
        .toList();
    double totalRepaidForThisLoan = repaymentsForThisLoan.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    int durationValue = int.tryParse(details.loanDuration.split(' ')[0]) ?? 1;
    String unit = details.loanDuration.split(' ')[1];
    List<Installment> installments = [];
    final loanDate = DateTime.tryParse(loan.date) ?? DateTime.now();

    for (int i = 1; i <= durationValue; i++) {
      DateTime dueDate;
      if (unit == 'days') {
        dueDate = loanDate.add(Duration(days: i));
      } else if (unit == 'weeks') {
        dueDate = loanDate.add(Duration(days: i * 7));
      } else {
        dueDate = DateTime(loanDate.year, loanDate.month + i, loanDate.day);
      }

      double amountAlreadyPaidForThisInstallment =
          (totalRepaidForThisLoan - (details.installmentAmount * (i - 1)))
              .clamp(0.0, details.installmentAmount);
      double remainingForThisInstallment =
          details.installmentAmount - amountAlreadyPaidForThisInstallment;
      String status;

      if (remainingForThisInstallment <= 0.01) {
        status = "Paid";
      } else if (dueDate.isBefore(DateTime.now())) {
        status = "Overdue";
      } else {
        status = "Upcoming";
      }

      installments.add(
        Installment(
          dueDate: dueDate,
          amount: remainingForThisInstallment,
          status: status,
        ),
      );
    }
    return installments;
  }

  Future<List<LoanRecord>> getCustomerLoans(String customerId) async {
    final customerTransactions = await _transactionsDao
        .getTransactionsForCustomer(customerId);
    final allRepayments = customerTransactions
        .where((t) => t.type == TransactionType.repayment)
        .toList();
    final allLoans = customerTransactions
        .where((t) => t.type == TransactionType.loan)
        .toList();
    final Map<String, double> repaymentsByLoanId = {};

    for (final repayment in allRepayments) {
      final noteParts = repayment.note.split(':');
      if (noteParts.length == 2) {
        final loanId = noteParts[1].trim();
        repaymentsByLoanId[loanId] =
            (repaymentsByLoanId[loanId] ?? 0) + repayment.amount;
      }
    }

    final List<LoanRecord> activeLoans = [];
    for (final loan in allLoans) {
      final totalOwedForThisLoan = loan.amount;
      final totalRepaidForThisLoan = repaymentsByLoanId[loan.id] ?? 0.0;
      final remainingBalance = totalOwedForThisLoan - totalRepaidForThisLoan;

      if (remainingBalance > 0.01) {
        final loanRecord = LoanRecord.fromTransaction(loan, remainingBalance);
        if (loan.loanKind == 'soft') {
          loanRecord.installments = await getInstallmentsForLoan(loanRecord);
        }
        activeLoans.add(loanRecord);
      }
    }
    return activeLoans;
  }

  // --- Calculation Methods ---
  double computeBalance(String customerId) {
    double balance = 0.0;
    for (final t in transactions.where((t) => t.customerId == customerId)) {
      if (t.type == TransactionType.loan) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance > 0.01 ? balance : 0.0;
  }

  Future<int> getActiveLoanCount() async {
    int count = 0;
    for (final customer in customers) {
      // Use await here
      final customerLoans = await getCustomerLoans(customer.id);
      count += customerLoans.length;
    }
    return count;
  }

  // (All other calculation methods like getLoansToday, totalOutstanding, etc. are fine)
  double getLoansToday() {
    final today = DateTime.now();
    final todayDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    return transactions
        .where(
          (t) => t.type == TransactionType.loan && t.date.startsWith(todayDate),
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  int totalCustomers() => customers.length;

  double totalOutstanding() {
    return customers.fold(0.0, (sum, c) => sum + computeBalance(c.id));
  }
}
