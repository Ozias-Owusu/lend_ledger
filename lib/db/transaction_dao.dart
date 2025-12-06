import 'package:lend_ledger/models/transactionRecord.dart';
import 'database_helper.dart';

class TransactionsDao {
  // Use the new TransactionRecord model
  Future<int> insertTransaction(TransactionRecord record) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(DatabaseHelper.tableTransactions, record.toJson());
  }

  Future<List<TransactionRecord>> getTransactionsForCustomer(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      DatabaseHelper.tableTransactions,
      where: "${DatabaseHelper.columnCustomerId} = ?",
      whereArgs: [customerId],
      orderBy: "${DatabaseHelper.columnDate} DESC",
    );
    return result.map((e) => TransactionRecord.fromJson(e)).toList();
  }

  Future<int> deleteTransactionsForCustomer(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
        DatabaseHelper.tableTransactions,
        where: "${DatabaseHelper.columnCustomerId} = ?",
        whereArgs: [customerId]
    );
  }
  // ADD THIS NEW METHOD
  Future<List<TransactionRecord>> getAllTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(DatabaseHelper.tableTransactions);
    return result.map((e) => TransactionRecord.fromJson(e)).toList();
  }
}
