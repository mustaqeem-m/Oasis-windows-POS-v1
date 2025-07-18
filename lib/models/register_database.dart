
import 'package:sqflite/sqflite.dart';
import 'database.dart';

class RegisterDatabase {
  Future<void> createTable(Database db) async {
    await db.execute("""
      CREATE TABLE IF NOT EXISTS register_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        opening_balance REAL NOT NULL,
        closing_balance REAL,
        opened_at TEXT NOT NULL,
        closed_at TEXT
      )
    """);
  }

  Future<int> insertOpeningBalance(double openingBalance) async {
    final db = await DbProvider.db.database;
    return await db.insert('register_sessions', {
      'opening_balance': openingBalance,
      'opened_at': DateTime.now().toIso8601String(),
    });
  }

  Future<double> getOpeningBalance() async {
    final db = await DbProvider.db.database;
    final result = await db.query(
      'register_sessions',
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['opening_balance'] as double;
    }
    return 0.0;
  }
}
