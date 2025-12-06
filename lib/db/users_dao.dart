import 'package:lend_ledger/models/user.dart';
import 'database_helper.dart';

class UsersDao {
  Future<int> insertUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert("users", user.toJson());
  }

  Future<User?> login(String email, String password) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      "users",
      where: "email = ? AND password = ?",
      whereArgs: [email, password],
    );

    if (result.isEmpty) return null;
    return User.fromJson(result.first);
  }
}
