
import 'package:sqflite/sqflite.dart';
import 'database.dart';

class ExpenseDatabase {
  Future<void> createTable(Database db) async {
    await db.execute("""
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL
      )
    """);
  }

  Future<int> insertExpense(double amount, String? note) async {
    final db = await DbProvider.db.database;
    return await db.insert('expenses', {
      'amount': amount,
      'note': note,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await DbProvider.db.database;
    return await db.query('expenses');
  }
}
