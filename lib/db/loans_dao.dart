import 'package:lend_ledger/models/loan_record.dart';
import 'package:lend_ledger/models/transactionRecord.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

class LoansDao {
  Future<int> insertLoan(LoanRecord record) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert("loans", record.toJson());
  }

  Future<List<LoanRecord>> getLoansForCustomer(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      "loans",
      where: "customerId = ?",
      whereArgs: [customerId],
      orderBy: "date DESC",
    );
    return result.map((e) => LoanRecord.fromJson(e)).toList();
  }

  Future<double> computeBalance(String customerId) async {
    final loans = await getLoansForCustomer(customerId);

    double balance = 0;
    for (var t in loans) {
      if (t.type == TransactionType.loan) {
        balance += t.amount + (t.amount * t.interestPercent / 100);
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }
}
