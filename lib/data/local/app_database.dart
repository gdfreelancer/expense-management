import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'default_categories.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final root = await getDatabasesPath();
    _db = await openDatabase(
      p.join(root, 'pennywise.db'),
      version: 3,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys=ON'),
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE accounts(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,type TEXT NOT NULL,opening_minor INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL)');
        await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,type TEXT NOT NULL,icon TEXT NOT NULL DEFAULT "category",color INTEGER NOT NULL DEFAULT 4286019442,is_default INTEGER NOT NULL DEFAULT 0,parent_id INTEGER REFERENCES categories(id) ON DELETE RESTRICT)');
        await db.execute("CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,amount_minor INTEGER NOT NULL CHECK(amount_minor>0),type TEXT NOT NULL CHECK(type IN ('income','expense')),category_id INTEGER NOT NULL,account_id INTEGER NOT NULL,date_ms INTEGER NOT NULL,note TEXT NOT NULL DEFAULT '',created_at INTEGER NOT NULL,updated_at INTEGER NOT NULL,FOREIGN KEY(category_id) REFERENCES categories(id),FOREIGN KEY(account_id) REFERENCES accounts(id))");
        await db.execute('CREATE TABLE budgets(id INTEGER PRIMARY KEY AUTOINCREMENT,category_id INTEGER NOT NULL,amount_minor INTEGER NOT NULL,month_key TEXT NOT NULL,UNIQUE(category_id,month_key),FOREIGN KEY(category_id) REFERENCES categories(id))');
        await db.execute('CREATE TABLE recurring(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,amount_minor INTEGER NOT NULL,type TEXT NOT NULL,category_id INTEGER NOT NULL,account_id INTEGER NOT NULL,frequency TEXT NOT NULL,next_date_ms INTEGER NOT NULL,is_active INTEGER NOT NULL DEFAULT 1)');
        await db.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,target_minor INTEGER NOT NULL,saved_minor INTEGER NOT NULL DEFAULT 0,target_date_ms INTEGER)');
        await _createDebtsTable(db);
        await db.execute('CREATE INDEX idx_transactions_date ON transactions(date_ms DESC)');
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.insert('accounts', {'name':'Cash','type':'cash','opening_minor':0,'created_at':now});
        await db.insert('accounts', {'name':'Bank account','type':'bank','opening_minor':0,'created_at':now});
        await _seedCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createDebtsTable(db);
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE categories ADD COLUMN parent_id INTEGER REFERENCES categories(id) ON DELETE RESTRICT');
          const legacyNames = [
            ['Food & dining','Food & Dining','expense'],
            ['Transport','Transportation','expense'],
            ['Bills','Bills & Utilities','expense'],
            ['Health','Health & Medical','expense'],
            ['Investment','Investments','income'],
            ['Other income','Other Income','income'],
          ];
          for (final entry in legacyNames) {
            await db.update('categories', {'name':entry[1]}, where:'name=? AND type=? AND parent_id IS NULL', whereArgs:[entry[0],entry[2]]);
          }
          await _seedCategories(db);
          await _moveLegacyCategory(db, 'Groceries', 'expense', 'Food & Dining');
          await _moveLegacyCategory(db, 'Salary', 'income', 'Employment');
          await _moveLegacyCategory(db, 'Other', 'expense', 'Other Expenses');
        }
      },
    );
    return _db!;
  }

  Future<void> _seedCategories(DatabaseExecutor db) async {
    final ids = <String, int>{};
    for (final row in DefaultCategories.rows()) {
      final name = row['name'] as String;
      final type = row['type'] as String;
      final parentName = row['parent'] as String?;
      int? parentId = parentName == null ? null : ids['$type:$parentName'];
      if (parentName != null && parentId == null) {
        final parents = await db.query('categories', columns: ['id'], where: 'name=? AND type=? AND parent_id IS NULL', whereArgs: [parentName, type], limit: 1);
        if (parents.isNotEmpty) parentId = parents.first['id'] as int;
      }
      final existing = await db.query('categories', columns: ['id'], where: 'name=? AND type=? AND parent_id IS ?', whereArgs: [name, type, parentId], limit: 1);
      if (existing.isNotEmpty) { ids['$type:$name'] = existing.first['id'] as int; continue; }
      final id = await db.insert('categories', {'name':name,'type':type,'is_default':1,'parent_id':parentId});
      ids['$type:$name'] = id;
    }
  }

  Future<void> _moveLegacyCategory(DatabaseExecutor db, String name, String type, String parentName) async {
    final legacy = await db.query('categories', columns:['id'], where:'name=? AND type=? AND parent_id IS NULL', whereArgs:[name,type], limit:1);
    final parent = await db.query('categories', columns:['id'], where:'name=? AND type=? AND parent_id IS NULL', whereArgs:[parentName,type], limit:1);
    if (legacy.isEmpty || parent.isEmpty) return;
    final legacyId = legacy.first['id'] as int;
    final parentId = parent.first['id'] as int;
    final duplicate = await db.query('categories', columns:['id'], where:'name=? AND type=? AND parent_id=?', whereArgs:[name,type,parentId], limit:1);
    if (duplicate.isNotEmpty) await db.delete('categories', where:'id=?', whereArgs:[duplicate.first['id']]);
    await db.update('categories', {'parent_id':parentId}, where:'id=?', whereArgs:[legacyId]);
  }

  Future<void> _createDebtsTable(DatabaseExecutor db) async {
    await db.execute('CREATE TABLE debts(id INTEGER PRIMARY KEY AUTOINCREMENT,person TEXT NOT NULL,direction TEXT NOT NULL,amount_minor INTEGER NOT NULL,remaining_minor INTEGER NOT NULL,due_date_ms INTEGER,note TEXT NOT NULL DEFAULT "")');
  }
}
