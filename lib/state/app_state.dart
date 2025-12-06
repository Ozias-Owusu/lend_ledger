//
// import 'package:flutter/foundation.dart';
// import 'package:lend_ledger/db/customers_dao.dart';
// import 'package:lend_ledger/db/transaction_dao.dart';
// import 'package:lend_ledger/models/customer.dart';
// import 'package:lend_ledger/models/loan_record.dart';
// import 'package:lend_ledger/models/transactionRecord.dart';
// import 'package:uuid/uuid.dart';
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
//   bool isLoggedIn = false; // Simple auth state
//   String loggedInEmail = '';
//
//   // --- Core Data Loading Method ---
//   Future<void> loadFromDb() async {
//     customers = await _customersDao.getAllCustomers();
//     transactions = await _transactionsDao.getAllTransactions();
//     // This is the only place we should call notifyListeners() for data changes
//     notifyListeners();
//   }
//
//   // --- Auth (very simple, does not persist yet) ---
//   Future<bool> login(String email, String password) async {
//     if (email.isEmpty || password.isEmpty) return false;
//     loggedInEmail = email;
//     isLoggedIn = true;
//     notifyListeners();
//     return true;
//   }
//
//   Future<bool> signUp(
//       {required String name,
//         required String email,
//         required String password}) async {
//     if (name.isEmpty || email.isEmpty || password.length < 6) {
//       return false;
//     }
//     loggedInEmail = email;
//     isLoggedIn = true;
//     notifyListeners();
//     return true;
//   }
//
//   Future<void> logout() async {
//     isLoggedIn = false;
//     loggedInEmail = '';
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
//     // 1. Insert into DB
//     await _customersDao.insertCustomer(newCustomer);
//     // 2. Reload state from DB to update UI
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
//     // 1. Update in DB
//     await _customersDao.updateCustomer(updatedCustomer);
//     // 2. Reload state from DB
//     await loadFromDb();
//   }
//
//   Future<void> deleteCustomer(String customerId) async {
//     // 1. Delete from DB (transactions are deleted automatically via CASCADE)
//     await _customersDao.deleteCustomer(customerId);
//     // 2. Reload state from DB
//     await loadFromDb();
//   }
//
//   // --- Transaction Operations (DB Only) ---
//   Future<void> addTransaction({
//     required String customerId,
//     required TransactionType type,
//     required String loanKind,
//     required double amount,
//     double interestPercent = 0.0,
//     required String date,
//     String note = '',
//   }) async {
//     final newTransaction = TransactionRecord(
//       id: _uuid.v4(),
//       customerId: customerId,
//       type: type,
//       loanKind: loanKind,
//       amount: amount,
//       interestPercent: interestPercent,
//       date: date,
//       note: note,
//     );
//     // 1. Insert into DB
//     await _transactionsDao.insertTransaction(newTransaction);
//     // 2. Reload state from DB
//     await loadFromDb();
//   }
//
//   // --- Getter and Calculation Methods (operate on in-memory lists) ---
//
//   List<TransactionRecord> transactionsForCustomer(String customerId) {
//     final list =
//     transactions.where((t) => t.customerId == customerId).toList();
//     list.sort((a, b) => b.date.compareTo(a.date));
//     return list;
//   }
//
//   List<LoanRecord> getCustomerLoans(String customerId) {
//     final customerTransactions = transactionsForCustomer(customerId);
//     final totalRepaid = customerTransactions
//         .where((t) => t.type == TransactionType.repayment)
//         .fold(0.0, (sum, t) => sum + t.amount);
//     final loans =
//     customerTransactions.where((t) => t.type == TransactionType.loan).toList();
//     final List<LoanRecord> activeLoans = [];
//     double repaymentsApplied = 0;
//     for (final loan in loans.reversed) {
//       final totalOwedForThisLoan =
//           loan.amount + (loan.amount * (loan.interestPercent / 100));
//       final applicableRepayment =
//       (totalRepaid - repaymentsApplied).clamp(0.0, totalOwedForThisLoan);
//       final remainingBalance = totalOwedForThisLoan - applicableRepayment;
//       repaymentsApplied += applicableRepayment;
//       if (remainingBalance > 0.01) {
//         activeLoans.add(LoanRecord.fromTransaction(loan, remainingBalance));
//       }
//     }
//     return activeLoans.reversed.toList();
//   }
//
//   double computeBalance(String customerId) {
//     double balance = 0.0;
//     for (final t in transactionsForCustomer(customerId)) {
//       if (t.type == TransactionType.loan) {
//         final interestAmount = t.amount * (t.interestPercent / 100.0);
//         balance += t.amount + interestAmount;
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
//         .where((t) =>
//     t.type == TransactionType.loan && t.date.startsWith(todayDate))
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lend_ledger/db/customers_dao.dart';
import 'package:lend_ledger/db/transaction_dao.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:lend_ledger/models/loan_record.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class AppState extends ChangeNotifier {
  // --- DAOs are the single source of truth for DB interaction ---
  final CustomersDao _customersDao = CustomersDao();
  final TransactionsDao _transactionsDao = TransactionsDao();

  // --- In-memory cache of the database state ---
  List<Customer> customers = [];
  List<TransactionRecord> transactions = [];
  bool isLoggedIn = false;
  String loggedInEmail = '';
  String loggedInUserName = '';

  // --- Core Data Loading and Auth State ---
  Future<void> loadFromDb() async {
    // 1. Load business data from SQLite
    customers = await _customersDao.getAllCustomers();
    transactions = await _transactionsDao.getAllTransactions();

    // 2. Load auth state from SharedPreferences
    final sp = await SharedPreferences.getInstance();
    isLoggedIn = sp.getBool('isLoggedIn') ?? false;
    loggedInEmail = sp.getString('loggedInEmail') ?? '';
    loggedInUserName = sp.getString('loggedInUserName') ?? '';

    // 3. Notify UI
    notifyListeners();
  }

  // --- Authentication with SharedPreferences ---

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.isEmpty || email.isEmpty || password.length < 6) {
      return false;
    }
    final sp = await SharedPreferences.getInstance();
    // Save the new user's credentials
    await sp.setString('registered_email', email);
    await sp.setString('registered_password', password);
    await sp.setString('registered_name', name);

    // Automatically log them in
    isLoggedIn = true;
    loggedInEmail = email;
    loggedInUserName = name;
    await sp.setBool('isLoggedIn', true);
    await sp.setString('loggedInEmail', email);

    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    final sp = await SharedPreferences.getInstance();

    // Get the saved credentials
    final registeredEmail = sp.getString('registered_email');
    final registeredPassword = sp.getString('registered_password');
    final registeredName = sp.getString('registered_name') ?? '';

    // Check if the provided credentials match the saved ones
    if (email.isNotEmpty &&
        password.isNotEmpty &&
        email == registeredEmail &&
        password == registeredPassword) {
      // If they match, update the login state
      isLoggedIn = true;
      loggedInEmail = email;
      loggedInUserName = registeredName;
      await sp.setBool('isLoggedIn', true);
      await sp.setString('loggedInEmail', email);

      notifyListeners();
      return true;
    }

    // If they don't match, return false
    return false;
  }

  Future<void> setAppPin(String pin) async {
    if (pin.length != 6) return; // Ensure it's a 6-digit PIN
    final sp = await SharedPreferences.getInstance();
    await sp.setString('app_pin', pin); // In a real app, hash this!
  }

  // You can also add a method to verify the pin later
  Future<bool> verifyAppPin(String pin) async {
    final sp = await SharedPreferences.getInstance();
    final savedPin = sp.getString('app_pin');
    return savedPin == pin;
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    // Clear the session state
    isLoggedIn = false;
    loggedInEmail = '';
    loggedInUserName = '';
    await sp.setBool('isLoggedIn', false);
    await sp.setString('loggedInEmail', '');

    notifyListeners();
  }

  // --- Customer Operations (DB Only) ---
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

  // --- Transaction Operations (DB Only) ---
  Future<void> addTransaction({
    required String customerId,
    required TransactionType type,
    required String loanKind,
    required double amount,
    double interestPercent = 0.0,
    required String date,
    String note = '',
  }) async {
    final newTransaction = TransactionRecord(
      id: _uuid.v4(),
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

  // --- Getter and Calculation Methods (operate on in-memory lists) ---

  List<TransactionRecord> transactionsForCustomer(String customerId) {
    final list =
    transactions.where((t) => t.customerId == customerId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<LoanRecord> getCustomerLoans(String customerId) {
    final customerTransactions = transactionsForCustomer(customerId);
    final totalRepaid = customerTransactions
        .where((t) => t.type == TransactionType.repayment)
        .fold(0.0, (sum, t) => sum + t.amount);
    final loans =
    customerTransactions.where((t) => t.type == TransactionType.loan).toList();
    final List<LoanRecord> activeLoans = [];
    double repaymentsApplied = 0;
    for (final loan in loans.reversed) {
      final totalOwedForThisLoan =
          loan.amount + (loan.amount * (loan.interestPercent / 100));
      final applicableRepayment =
      (totalRepaid - repaymentsApplied).clamp(0.0, totalOwedForThisLoan);
      final remainingBalance = totalOwedForThisLoan - applicableRepayment;
      repaymentsApplied += applicableRepayment;
      if (remainingBalance > 0.01) {
        activeLoans.add(LoanRecord.fromTransaction(loan, remainingBalance));
      }
    }
    return activeLoans.reversed.toList();
  }

  double computeBalance(String customerId) {
    double balance = 0.0;
    for (final t in transactionsForCustomer(customerId)) {
      if (t.type == TransactionType.loan) {
        final interestAmount = t.amount * (t.interestPercent / 100.0);
        balance += t.amount + interestAmount;
      } else {
        balance -= t.amount;
      }
    }
    return balance > 0 ? balance : 0.0; // Ensure balance doesn't go negative
  }

  double totalBorrowed(String customerId) {
    return transactionsForCustomer(customerId)
        .where((t) => t.type == TransactionType.loan)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double totalRepaid(String customerId) {
    return transactionsForCustomer(customerId)
        .where((t) => t.type == TransactionType.repayment)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getLoansToday() {
    final today = DateTime.now();
    final todayDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    return transactions
        .where((t) =>
    t.type == TransactionType.loan && t.date.startsWith(todayDate))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  int getActiveLoanCount() {
    int count = 0;
    for (final customer in customers) {
      count += getCustomerLoans(customer.id).length;
    }
    return count;
  }

  int totalCustomers() => customers.length;

  double totalOutstanding() {
    return customers.fold(0.0, (sum, c) => sum + computeBalance(c.id));
  }
}
