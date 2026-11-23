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
      version: 5,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys=ON'),
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE accounts(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,type TEXT NOT NULL,opening_minor INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL)');
        await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,type TEXT NOT NULL,icon TEXT NOT NULL DEFAULT "category",color INTEGER NOT NULL DEFAULT 4286019442,is_default INTEGER NOT NULL DEFAULT 0,parent_id INTEGER REFERENCES categories(id) ON DELETE RESTRICT)');
        await _createTransactionsTable(db, 'transactions');
        await db.execute('CREATE TABLE budgets(id INTEGER PRIMARY KEY AUTOINCREMENT,category_id INTEGER NOT NULL,amount_minor INTEGER NOT NULL,month_key TEXT NOT NULL,UNIQUE(category_id,month_key),FOREIGN KEY(category_id) REFERENCES categories(id))');
        await db.execute('CREATE TABLE recurring(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,amount_minor INTEGER NOT NULL,type TEXT NOT NULL,category_id INTEGER NOT NULL,account_id INTEGER NOT NULL,frequency TEXT NOT NULL,next_date_ms INTEGER NOT NULL,is_active INTEGER NOT NULL DEFAULT 1)');
        await db.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,target_minor INTEGER NOT NULL,saved_minor INTEGER NOT NULL DEFAULT 0,target_date_ms INTEGER)');
        await _createDebtsTable(db);
        await _createPaymentModesTable(db);
        await db.execute('CREATE INDEX idx_transactions_date ON transactions(date_ms DESC)');
        await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id,subcategory_id)');
        await db.execute('CREATE INDEX idx_debts_person ON debts(person)');
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.insert('accounts', {'name':'Cash','type':'cash','opening_minor':0,'created_at':now});
        await db.insert('accounts', {'name':'Bank account','type':'bank','opening_minor':0,'created_at':now});
        await _seedCategories(db);
        await _seedPaymentModes(db);
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
        if (oldVersion < 4) {
          await _upgradeToV4(db);
        }
        if (oldVersion < 5) {
          await _seedCategories(db);
        }
      },
    );
    return _db!;
  }

  Future<void> _createTransactionsTable(DatabaseExecutor db, String table) async {
    await db.execute('CREATE TABLE $table(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,amount_minor INTEGER NOT NULL CHECK(amount_minor>0),type TEXT NOT NULL CHECK(type IN (\'expense\',\'profit\',\'loss\')),category_id INTEGER NOT NULL,subcategory_id INTEGER,payment_mode_id INTEGER,sub_payment_mode_id INTEGER,account_id INTEGER NOT NULL,date_ms INTEGER NOT NULL,note TEXT NOT NULL DEFAULT \'\',created_at INTEGER NOT NULL,updated_at INTEGER NOT NULL,FOREIGN KEY(category_id) REFERENCES categories(id),FOREIGN KEY(subcategory_id) REFERENCES categories(id),FOREIGN KEY(payment_mode_id) REFERENCES payment_modes(id),FOREIGN KEY(sub_payment_mode_id) REFERENCES payment_modes(id),FOREIGN KEY(account_id) REFERENCES accounts(id))');
  }

  Future<void> _createPaymentModesTable(DatabaseExecutor db) async {
    await db.execute('CREATE TABLE payment_modes(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,parent_id INTEGER REFERENCES payment_modes(id) ON DELETE RESTRICT,is_default INTEGER NOT NULL DEFAULT 0)');
  }

  Future<void> _createDebtsTable(DatabaseExecutor db) async {
    await db.execute('CREATE TABLE debts(id INTEGER PRIMARY KEY AUTOINCREMENT,person TEXT NOT NULL,direction TEXT NOT NULL,amount_minor INTEGER NOT NULL,remaining_minor INTEGER NOT NULL,due_date_ms INTEGER,date_ms INTEGER NOT NULL,description TEXT NOT NULL DEFAULT \'\',return_note TEXT NOT NULL DEFAULT \'\',note TEXT NOT NULL DEFAULT \'\')');
    await db.execute('CREATE TABLE debt_repayments(id INTEGER PRIMARY KEY AUTOINCREMENT,debt_id INTEGER NOT NULL,amount_minor INTEGER NOT NULL,date_ms INTEGER NOT NULL,note TEXT NOT NULL DEFAULT \'\',FOREIGN KEY(debt_id) REFERENCES debts(id) ON DELETE CASCADE)');
  }

  Future<void> _upgradeToV4(DatabaseExecutor db) async {
    // Income categories become main-level only. Existing category IDs are retained.
    await db.execute("UPDATE categories SET parent_id=NULL WHERE type='income' AND parent_id IS NOT NULL");

    // Flatten legacy expense trees deeper than main/subcategory without deleting IDs.
    final deepCategories = await db.rawQuery(
      "SELECT c.id,c.parent_id FROM categories c JOIN categories p ON p.id=c.parent_id WHERE c.type='expense' AND p.parent_id IS NOT NULL",
    );
    for (final row in deepCategories) {
      final id = row['id'] as int;
      var rootId = row['parent_id'] as int;
      while (true) {
        final ancestor = await db.query('categories', columns:['parent_id'], where:'id=?', whereArgs:[rootId], limit:1);
        if (ancestor.isEmpty || ancestor.first['parent_id'] == null) break;
        rootId = ancestor.first['parent_id'] as int;
      }
      await db.update('categories', {'parent_id':rootId}, where:'id=?', whereArgs:[id]);
    }

    // Seed newly available defaults for existing installations without replacing user data.
    await _seedCategories(db);
    await _createPaymentModesTable(db);
    await _seedPaymentModes(db);

    // Ensure every existing expense main category has a usable subcategory.
    final roots = await db.query('categories', columns:['id','name'], where:"type='expense' AND parent_id IS NULL");
    for (final root in roots) {
      final rootId = root['id'] as int;
      final children = await db.query('categories', columns:['id'], where:'parent_id=?', whereArgs:[rootId], limit:1);
      if (children.isEmpty) {
        await db.insert('categories', {'name':'Other','type':'expense','parent_id':rootId,'is_default':1});
      }
    }

    final oldRows = await db.query('transactions', orderBy:'id');
    await db.execute('DROP INDEX IF EXISTS idx_transactions_date');
    await db.execute('ALTER TABLE transactions RENAME TO transactions_v3');
    await _createTransactionsTable(db, 'transactions');
    final otherMode = await db.query('payment_modes', columns:['id'], where:'name=? AND parent_id IS NULL', whereArgs:['Other'], limit:1);
    final otherModeId = otherMode.first['id'] as int;
    final otherSub = await db.query('payment_modes', columns:['id'], where:'name=? AND parent_id=?', whereArgs:['Other',otherModeId], limit:1);
    final otherSubId = otherSub.first['id'] as int;
    for (final row in oldRows) {
      final oldType = row['type'] as String;
      final type = oldType == 'income' ? 'profit' : 'expense';
      var categoryId = row['category_id'] as int;
      int? subcategoryId;
      if (type == 'expense') {
        final category = await db.query('categories', columns:['id','parent_id'], where:'id=?', whereArgs:[categoryId], limit:1);
        if (category.isNotEmpty && category.first['parent_id'] != null) {
          subcategoryId = categoryId;
          categoryId = category.first['parent_id'] as int;
        } else {
          final existingOther = await db.query('categories', columns:['id'], where:"parent_id=? AND name='Other'", whereArgs:[categoryId], limit:1);
          final firstChild = existingOther.isNotEmpty ? existingOther : await db.query('categories', columns:['id'], where:'parent_id=?', whereArgs:[categoryId], limit:1);
          if (firstChild.isNotEmpty) subcategoryId = firstChild.first['id'] as int;
        }
      }
      await db.insert('transactions', {
        'id':row['id'],'title':row['title'],'amount_minor':row['amount_minor'],'type':type,
        'category_id':categoryId,'subcategory_id':subcategoryId,
        'payment_mode_id':type == 'expense' ? otherModeId : null,
        'sub_payment_mode_id':type == 'expense' ? otherSubId : null,
        'account_id':row['account_id'],'date_ms':row['date_ms'],'note':row['note'] ?? '',
        'created_at':row['created_at'] ?? row['date_ms'],'updated_at':row['updated_at'] ?? row['date_ms'],
      });
    }
    await db.execute('DROP TABLE transactions_v3');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date_ms DESC)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id,subcategory_id)');

    // Extend the original debt tracker instead of replacing it, preserving all existing debts.
    final debtColumns = (await db.rawQuery('PRAGMA table_info(debts)')).map((e)=>e['name'] as String).toSet();
    if (!debtColumns.contains('date_ms')) await db.execute('ALTER TABLE debts ADD COLUMN date_ms INTEGER NOT NULL DEFAULT 0');
    if (!debtColumns.contains('description')) await db.execute("ALTER TABLE debts ADD COLUMN description TEXT NOT NULL DEFAULT ''");
    if (!debtColumns.contains('return_note')) await db.execute("ALTER TABLE debts ADD COLUMN return_note TEXT NOT NULL DEFAULT ''");
    await db.execute('UPDATE debts SET date_ms=COALESCE(NULLIF(date_ms,0),due_date_ms,?)', [DateTime.now().millisecondsSinceEpoch]);
    await db.execute('CREATE TABLE IF NOT EXISTS debt_repayments(id INTEGER PRIMARY KEY AUTOINCREMENT,debt_id INTEGER NOT NULL,amount_minor INTEGER NOT NULL,date_ms INTEGER NOT NULL,note TEXT NOT NULL DEFAULT \'\',FOREIGN KEY(debt_id) REFERENCES debts(id) ON DELETE CASCADE)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_person ON debts(person)');
  }

  Future<void> _seedCategories(DatabaseExecutor db) async {
    final ids = <String, int>{};
    for (final row in DefaultCategories.rows()) {
      final name = row['name'] as String;
      final type = row['type'] as String;
      final parentName = row['parent'] as String?;
      int? parentId = parentName == null ? null : ids['$type:$parentName'];
      if (parentName != null && parentId == null) {
        final parents = await db.query('categories', columns:['id'], where:'name=? AND type=? AND parent_id IS NULL', whereArgs:[parentName,type], limit:1);
        if (parents.isNotEmpty) parentId = parents.first['id'] as int;
      }
      final existing = await db.query('categories', columns:['id'], where:'name=? AND type=? AND parent_id IS ?', whereArgs:[name,type,parentId], limit:1);
      if (existing.isNotEmpty) { ids['$type:$name'] = existing.first['id'] as int; continue; }
      final id = await db.insert('categories', {'name':name,'type':type,'is_default':1,'parent_id':parentId});
      ids['$type:$name'] = id;
    }
  }

  Future<void> _seedPaymentModes(DatabaseExecutor db) async {
    const defaults = <String, List<String>>{
      'UPI':['Google Pay','PhonePe','Paytm','BHIM','Other UPI'],
      'Bank Transfer':['NEFT','IMPS','RTGS','Other Bank Transfer'],
      'Card':['Credit Card','Debit Card','Other Card'],
      'Cash':['Cash'],
      'Wallet':['Paytm Wallet','Amazon Pay','Other Wallet'],
      'Cheque':['Cheque'],
      'Other':['Other'],
    };
    for (final entry in defaults.entries) {
      final parents = await db.query('payment_modes', columns:['id'], where:'name=? AND parent_id IS NULL', whereArgs:[entry.key], limit:1);
      final parentId = parents.isNotEmpty ? parents.first['id'] as int : await db.insert('payment_modes', {'name':entry.key,'is_default':1});
      for (final child in entry.value) {
        final exists = await db.query('payment_modes', columns:['id'], where:'name=? AND parent_id=?', whereArgs:[child,parentId], limit:1);
        if (exists.isEmpty) await db.insert('payment_modes', {'name':child,'parent_id':parentId,'is_default':1});
      }
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
}
