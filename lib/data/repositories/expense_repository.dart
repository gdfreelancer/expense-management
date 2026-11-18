import 'package:sqflite/sqflite.dart';
import '../../models/expense_transaction.dart';import '../local/app_database.dart';
class ExpenseRepository{
 final source=AppDatabase.instance;
 Future<List<Map<String,Object?>>> accounts()async=>(await(await source.database).query('accounts')).toList();
 Future<List<Map<String,Object?>>> categories({String? type})async=>(await(await source.database).query('categories',where:type==null?null:'type=?',whereArgs:type==null?null:[type],orderBy:'name')).toList();
 Future<List<ExpenseTransaction>> transactions({String? type,DateTime? from})async{final rows=await(await source.database).query('transactions',where:(type==null||type=='all')?(from==null?null:'date_ms>=?'):(from==null?'type=?':'type=? AND date_ms>=?'),whereArgs:(type==null||type=='all')?(from==null?null:[from.millisecondsSinceEpoch]):(from==null?[type]:[type,from.millisecondsSinceEpoch]),orderBy:'date_ms DESC,id DESC');return rows.map(ExpenseTransaction.fromMap).toList();}
 Future<void> save(ExpenseTransaction e)async{final db=await source.database;final m=e.toMap()..['updated_at']=DateTime.now().millisecondsSinceEpoch;if(e.id==null){m['created_at']=DateTime.now().millisecondsSinceEpoch;await db.insert('transactions',m);}else{await db.update('transactions',m,where:'id=?',whereArgs:[e.id]);}}
 Future<void> delete(int id)async{await(await source.database).delete('transactions',where:'id=?',whereArgs:[id]);}
 Future<Map<String,int>> totals(DateTime from,DateTime to)async{final rows=await(await source.database).rawQuery('SELECT type,SUM(amount_minor) total FROM transactions WHERE date_ms>=? AND date_ms<? GROUP BY type',[from.millisecondsSinceEpoch,to.millisecondsSinceEpoch]);final m={'income':0,'expense':0};for(final r in rows){m[r['type'] as String]=(r['total'] as int?)??0;}return m;}
 Future<int> balance(int id,int opening)async{final rows=await(await source.database).rawQuery('SELECT type,SUM(amount_minor) total FROM transactions WHERE account_id=? GROUP BY type',[id]);var n=opening;for(final r in rows){final v=(r['total'] as int?)??0;n+=r['type']=='income'?v:-v;}return n;}
 Future<List<Map<String,Object?>>> budgets(String month)async=>(await(await source.database).rawQuery("SELECT b.*,c.name category_name,COALESCE((SELECT SUM(t.amount_minor) FROM transactions t WHERE t.category_id=b.category_id AND t.type='expense' AND strftime('%Y-%m',datetime(t.date_ms/1000,'unixepoch','localtime'))=b.month_key),0) spent_minor FROM budgets b JOIN categories c ON c.id=b.category_id WHERE b.month_key=?",[month])).toList();
 Future<void> saveBudget(int c,int amount,String month)async{await(await source.database).insert('budgets',{'category_id':c,'amount_minor':amount,'month_key':month},conflictAlgorithm:ConflictAlgorithm.replace);}
 Future<void> addAccount(String n,String t,int opening)async{await(await source.database).insert('accounts',{'name':n,'type':t,'opening_minor':opening,'created_at':DateTime.now().millisecondsSinceEpoch});}
 Future<void> addCategory(String n,String t)async{await(await source.database).insert('categories',{'name':n,'type':t,'is_default':0});}
 Future<List<Map<String,Object?>>> recurring()async=>(await(await source.database).rawQuery('SELECT r.*,c.name category_name FROM recurring r LEFT JOIN categories c ON c.id=r.category_id ORDER BY r.next_date_ms')).toList();
 Future<void> addRecurring(String title,int amount,String type,int category,int account,String frequency,DateTime next)async{await(await source.database).insert('recurring',{'title':title,'amount_minor':amount,'type':type,'category_id':category,'account_id':account,'frequency':frequency,'next_date_ms':next.millisecondsSinceEpoch,'is_active':1});}
 Future<void> toggleRecurring(int id,bool active)async{await(await source.database).update('recurring',{'is_active':active?1:0},where:'id=?',whereArgs:[id]);}
 Future<List<Map<String,Object?>>> goals()async=>(await(await source.database).query('goals',orderBy:'id DESC')).toList();
 Future<void> addGoal(String name,int target)async{await(await source.database).insert('goals',{'name':name,'target_minor':target,'saved_minor':0});}
 Future<void> contributeGoal(int id,int amount)async{await(await source.database).rawUpdate('UPDATE goals SET saved_minor=saved_minor+? WHERE id=?',[amount,id]);}
 Future<List<Map<String,Object?>>> debts()async=>(await(await source.database).query('debts',orderBy:'id DESC')).toList();
 Future<void> addDebt(String person,String direction,int amount,{DateTime? due,String note=''})async{await(await source.database).insert('debts',{'person':person,'direction':direction,'amount_minor':amount,'remaining_minor':amount,'due_date_ms':due?.millisecondsSinceEpoch,'note':note});}
 Future<void> settleDebt(int id,int amount)async{await(await source.database).rawUpdate('UPDATE debts SET remaining_minor=MAX(0,remaining_minor-?) WHERE id=?',[amount,id]);}
}
