import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
class AppDatabase{
 AppDatabase._();static final instance=AppDatabase._();Database? _db;
 Future<Database> get database async{
  if(_db!=null)return _db!;final root=await getDatabasesPath();
  _db=await openDatabase(p.join(root,'pennywise.db'),version:1,onConfigure:(d)async{await d.execute('PRAGMA foreign_keys=ON');},onCreate:(d,v)async{
   await d.execute('CREATE TABLE accounts(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,type TEXT NOT NULL,opening_minor INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL)');
   await d.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,type TEXT NOT NULL,icon TEXT NOT NULL DEFAULT "category",color INTEGER NOT NULL DEFAULT 4286019442,is_default INTEGER NOT NULL DEFAULT 0)');
   await d.execute("CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,amount_minor INTEGER NOT NULL CHECK(amount_minor>0),type TEXT NOT NULL CHECK(type IN ('income','expense')),category_id INTEGER NOT NULL,account_id INTEGER NOT NULL,date_ms INTEGER NOT NULL,note TEXT NOT NULL DEFAULT '',created_at INTEGER NOT NULL,updated_at INTEGER NOT NULL,FOREIGN KEY(category_id) REFERENCES categories(id),FOREIGN KEY(account_id) REFERENCES accounts(id))");
   await d.execute('CREATE TABLE budgets(id INTEGER PRIMARY KEY AUTOINCREMENT,category_id INTEGER NOT NULL,amount_minor INTEGER NOT NULL,month_key TEXT NOT NULL,UNIQUE(category_id,month_key),FOREIGN KEY(category_id) REFERENCES categories(id))');
   await d.execute('CREATE TABLE recurring(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,amount_minor INTEGER NOT NULL,type TEXT NOT NULL,category_id INTEGER NOT NULL,account_id INTEGER NOT NULL,frequency TEXT NOT NULL,next_date_ms INTEGER NOT NULL,is_active INTEGER NOT NULL DEFAULT 1)');
   await d.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,target_minor INTEGER NOT NULL,saved_minor INTEGER NOT NULL DEFAULT 0,target_date_ms INTEGER)');
   await d.execute('CREATE TABLE debts(id INTEGER PRIMARY KEY AUTOINCREMENT,person TEXT NOT NULL,direction TEXT NOT NULL,amount_minor INTEGER NOT NULL,remaining_minor INTEGER NOT NULL,due_date_ms INTEGER,note TEXT NOT NULL DEFAULT "")');
   await d.execute('CREATE INDEX idx_transactions_date ON transactions(date_ms DESC)');
   final now=DateTime.now().millisecondsSinceEpoch;await d.insert('accounts',{'name':'Cash','type':'cash','opening_minor':0,'created_at':now});await d.insert('accounts',{'name':'Bank account','type':'bank','opening_minor':0,'created_at':now});
   final rows=[['Food & dining','expense'],['Transport','expense'],['Shopping','expense'],['Bills','expense'],['Health','expense'],['Entertainment','expense'],['Groceries','expense'],['Other','expense'],['Salary','income'],['Business','income'],['Investment','income'],['Other income','income']];
   for(final r in rows){await d.insert('categories',{'name':r[0],'type':r[1],'is_default':1});}
  });return _db!;
 }
}
