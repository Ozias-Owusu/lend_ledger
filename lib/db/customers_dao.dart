import 'package:lend_ledger/models/customer.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class CustomersDao {
  Future<int> insertCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(DatabaseHelper.tableCustomers, customer.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(DatabaseHelper.tableCustomers, orderBy: "${DatabaseHelper.columnName} ASC");
    return result.map((e) => Customer.fromJson(e)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(DatabaseHelper.tableCustomers, customer.toJson(),
        where: "${DatabaseHelper.columnId} = ?", whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(DatabaseHelper.tableCustomers,
        where: "${DatabaseHelper.columnId} = ?", whereArgs: [customerId]);
  }
}
