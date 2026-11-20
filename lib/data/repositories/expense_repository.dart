import 'package:sqflite/sqflite.dart';
import '../../models/expense_transaction.dart';
import '../local/app_database.dart';

class ExpenseRepository {
  final source = AppDatabase.instance;

  Future<List<Map<String, Object?>>> accounts() async =>
      (await (await source.database).query('accounts', orderBy: 'name')).toList();

  Future<List<Map<String, Object?>>> categories({String? type}) async =>
      (await (await source.database).query('categories', where: type == null ? null : 'type=?', whereArgs: type == null ? null : [type], orderBy: 'name')).toList();

  Future<List<ExpenseTransaction>> transactions({String? type, DateTime? from}) async {
    final all = type == null || type == 'all';
    final rows = await (await source.database).query('transactions',
      where: all ? (from == null ? null : 'date_ms>=?') : (from == null ? 'type=?' : 'type=? AND date_ms>=?'),
      whereArgs: all ? (from == null ? null : [from.millisecondsSinceEpoch]) : (from == null ? [type] : [type, from.millisecondsSinceEpoch]),
      orderBy: 'date_ms DESC,id DESC');
    return rows.map(ExpenseTransaction.fromMap).toList();
  }

  Future<void> save(ExpenseTransaction e) async {
    final db = await source.database;
    final map = e.toMap()..['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    if (e.id == null) { map['created_at'] = DateTime.now().millisecondsSinceEpoch; await db.insert('transactions', map); }
    else { await db.update('transactions', map, where: 'id=?', whereArgs: [e.id]); }
  }
  Future<void> delete(int id) async { await (await source.database).delete('transactions', where: 'id=?', whereArgs: [id]); }

  Future<Map<String, int>> totals(DateTime from, DateTime to) async {
    final rows = await (await source.database).rawQuery('SELECT type,SUM(amount_minor) total FROM transactions WHERE date_ms>=? AND date_ms<? GROUP BY type', [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch]);
    final result = {'income': 0, 'expense': 0};
    for (final row in rows) { result[row['type'] as String] = (row['total'] as int?) ?? 0; }
    return result;
  }

  Future<int> balance(int id, int opening) async {
    final rows = await (await source.database).rawQuery('SELECT type,SUM(amount_minor) total FROM transactions WHERE account_id=? GROUP BY type', [id]);
    var value = opening;
    for (final row in rows) { final amount = (row['total'] as int?) ?? 0; value += row['type'] == 'income' ? amount : -amount; }
    return value;
  }

  Future<List<Map<String, Object?>>> budgets(String month) async =>
      (await (await source.database).rawQuery("SELECT b.*,c.name category_name,COALESCE((SELECT SUM(t.amount_minor) FROM transactions t WHERE t.category_id=b.category_id AND t.type='expense' AND strftime('%Y-%m',datetime(t.date_ms/1000,'unixepoch','localtime'))=b.month_key),0) spent_minor FROM budgets b JOIN categories c ON c.id=b.category_id WHERE b.month_key=?", [month])).toList();

  Future<void> saveBudget(int categoryId, int amount, String month) async {
    await (await source.database).insert('budgets', {'category_id': categoryId, 'amount_minor': amount, 'month_key': month}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addAccount(String name, String type, int opening) async {
    await (await source.database).insert('accounts', {'name': name, 'type': type, 'opening_minor': opening, 'created_at': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> addCategory(String name, String type) async {
    await (await source.database).insert('categories', {'name': name, 'type': type, 'is_default': 0});
  }

  Future<List<Map<String, Object?>>> recurring() async =>
      (await (await source.database).rawQuery('SELECT r.*,c.name category_name,a.name account_name FROM recurring r LEFT JOIN categories c ON c.id=r.category_id LEFT JOIN accounts a ON a.id=r.account_id ORDER BY r.next_date_ms')).toList();

  Future<void> addRecurring(String title, int amount, String type, int categoryId, int accountId, String frequency, DateTime nextDate) async {
    await (await source.database).insert('recurring', {'title': title, 'amount_minor': amount, 'type': type, 'category_id': categoryId, 'account_id': accountId, 'frequency': frequency, 'next_date_ms': nextDate.millisecondsSinceEpoch, 'is_active': 1});
  }

  Future<void> toggleRecurring(int id, bool active) async {
    await (await source.database).update('recurring', {'is_active': active ? 1 : 0}, where: 'id=?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> goals() async =>
      (await (await source.database).query('goals', orderBy: 'id DESC')).toList();

  Future<void> addGoal(String name, int target) async {
    await (await source.database).insert('goals', {'name': name, 'target_minor': target, 'saved_minor': 0});
  }

  Future<void> contributeGoal(int id, int amount) async {
    await (await source.database).rawUpdate('UPDATE goals SET saved_minor=saved_minor+? WHERE id=?', [amount, id]);
  }

  Future<List<Map<String, Object?>>> debts() async =>
      (await (await source.database).query('debts', orderBy: 'id DESC')).toList();

  Future<void> addDebt(String person, String direction, int amount) async {
    await (await source.database).insert('debts', {'person': person, 'direction': direction, 'amount_minor': amount, 'remaining_minor': amount});
  }

  Future<void> settleDebt(int id, int amount) async {
    await (await source.database).rawUpdate('UPDATE debts SET remaining_minor=MAX(0,remaining_minor-?) WHERE id=?', [amount, id]);
  }
}