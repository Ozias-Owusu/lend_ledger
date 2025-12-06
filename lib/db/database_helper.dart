import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "LendLedger.db";
  static const _databaseVersion = 3;

  // --- Customer Table ---
  static const tableCustomers = 'customers';
  static const columnId = 'id';
  static const columnName = 'name';
  static const columnPhone = 'phone';
  static const columnGhanaCardNumber = 'ghanaCardNumber';
  static const columnLicenseIdNumber = 'licenseIdNumber';
  static const columnDateJoined = 'dateJoined';

  // --- Transactions Table ---
  static const tableTransactions = 'transactions';
  // Re-use columnId
  static const columnCustomerId = 'customerId';
  static const columnType = 'type';
  static const columnLoanKind = 'loanKind';
  static const columnAmount = 'amount';
  static const columnInterestPercent = 'interestPercent';
  static const columnDate = 'date';
  static const columnNote = 'note';


  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  // Add this new method to database_helper.dart
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // We are upgrading from version 1 to 2
      await db.execute('ALTER TABLE $tableCustomers ADD COLUMN ghanaCardFrontImage TEXT');
      await db.execute('ALTER TABLE $tableCustomers ADD COLUMN ghanaCardBackImage TEXT');
      await db.execute('ALTER TABLE $tableCustomers ADD COLUMN licenseFrontImage TEXT');
      await db.execute('ALTER TABLE $tableCustomers ADD COLUMN licenseBackImage TEXT');
    }
    if(oldVersion<3){
      await db.execute('ALTER TABLE $tableCustomers ADD COLUMN loanType TEXT');
    }
  }

  // SQL code to create the database tables
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableCustomers (
            $columnId TEXT PRIMARY KEY,
            $columnName TEXT NOT NULL,
            $columnPhone TEXT NOT NULL,
            $columnGhanaCardNumber TEXT,
            $columnLicenseIdNumber TEXT,
            $columnDateJoined TEXT NOT NULL,
            ghanaCardFrontImage TEXT,
            ghanaCardBackImage TEXT,
            licenseFrontImage TEXT,
            licenseBackImage TEXT,
            loanType TEXT
          )
          ''');

    await db.execute('''
          CREATE TABLE $tableTransactions (
            $columnId TEXT PRIMARY KEY,
            $columnCustomerId TEXT NOT NULL,
            $columnType TEXT NOT NULL,
            $columnLoanKind TEXT,
            $columnAmount REAL NOT NULL,
            $columnInterestPercent REAL NOT NULL,
            $columnDate TEXT NOT NULL,
            $columnNote TEXT,
            FOREIGN KEY ($columnCustomerId) REFERENCES $tableCustomers ($columnId) ON DELETE CASCADE
          )
          ''');
  }
}
