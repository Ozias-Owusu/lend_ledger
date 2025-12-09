
import 'package:lend_ledger/models/soft_loan_details.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SoftLoanDao {
  Future<int> insertSoftLoanDetails(SoftLoanDetails details) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      DatabaseHelper.tableSoftLoans,
      details.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SoftLoanDetails?> getSoftLoanDetails(String transactionId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      DatabaseHelper.tableSoftLoans,
      where: "${DatabaseHelper.columnTransactionId} = ?",
      whereArgs: [transactionId],
    );

    if (result.isNotEmpty) {
      return SoftLoanDetails.fromJson(result.first);
    }
    return null;
  }
}
