import 'package:sqflite/sqflite.dart';
import '../../models/expense_transaction.dart';
import '../local/app_database.dart';

class ExpenseRepository {
  final source = AppDatabase.instance;

  Future<List<Map<String, Object?>>> accounts() async =>
      (await (await source.database).query('accounts', orderBy:'name')).toList();

  Future<List<Map<String, Object?>>> categories({String? type}) async =>
      (await (await source.database).rawQuery(
        'SELECT c.*,p.name parent_name FROM categories c LEFT JOIN categories p ON p.id=c.parent_id ${type == null ? '' : 'WHERE c.type=?'} ORDER BY c.type,CASE WHEN c.parent_id IS NULL THEN c.id ELSE c.parent_id END,c.parent_id,c.name',
        type == null ? null : [type],
      )).toList();

  Future<List<Map<String, Object?>>> paymentModes() async =>
      (await (await source.database).rawQuery('SELECT c.*,p.name parent_name FROM payment_modes c LEFT JOIN payment_modes p ON p.id=c.parent_id ORDER BY CASE WHEN c.parent_id IS NULL THEN c.id ELSE c.parent_id END,c.parent_id,c.name')).toList();

  Future<List<ExpenseTransaction>> transactions({String? type, DateTime? from, DateTime? to}) async {
    final clauses=<String>[], args=<Object?>[];
    if (type=='profit_loss') { clauses.add("type IN ('profit','loss')"); }
    else if (type!=null && type!='all') { clauses.add('type=?'); args.add(type=='income'?'profit':type); }
    if (from!=null) { clauses.add('date_ms>=?'); args.add(from.millisecondsSinceEpoch); }
    if (to!=null) { clauses.add('date_ms<?'); args.add(to.millisecondsSinceEpoch); }
    final rows=await (await source.database).query('transactions',where:clauses.isEmpty?null:clauses.join(' AND '),whereArgs:args.isEmpty?null:args,orderBy:'date_ms DESC,id DESC');
    return rows.map(ExpenseTransaction.fromMap).toList();
  }

  Future<void> save(ExpenseTransaction item) async {
    final db=await source.database;
    if (!['expense','profit','loss'].contains(item.type)) throw ArgumentError.value(item.type,'type');
    final category=await db.query('categories',columns:['id','type','parent_id'],where:'id=?',whereArgs:[item.categoryId],limit:1);
    if(category.isEmpty || category.first['parent_id']!=null || category.first['type']!=(item.type=='expense'?'expense':'income')) throw StateError('Select a valid main category.');
    if(item.type=='expense') {
      if(item.subcategoryId==null || item.paymentModeId==null || item.subPaymentModeId==null) throw StateError('Expense subcategory and payment mode are required.');
      final sub=await db.query('categories',columns:['id','parent_id','type'],where:'id=?',whereArgs:[item.subcategoryId],limit:1);
      final mode=await db.query('payment_modes',columns:['id','parent_id'],where:'id=?',whereArgs:[item.paymentModeId],limit:1);
      final subMode=await db.query('payment_modes',columns:['id','parent_id'],where:'id=?',whereArgs:[item.subPaymentModeId],limit:1);
      if(sub.isEmpty || sub.first['parent_id']!=item.categoryId || sub.first['type']!='expense') throw StateError('Select a subcategory under the selected main category.');
      if(mode.isEmpty || mode.first['parent_id']!=null || subMode.isEmpty || subMode.first['parent_id']!=item.paymentModeId) throw StateError('Select a valid main and sub payment mode.');
    }
    final map=item.toMap()..['updated_at']=DateTime.now().millisecondsSinceEpoch;
    if(item.id==null){map['created_at']=DateTime.now().millisecondsSinceEpoch;await db.insert('transactions',map);}
    else {await db.update('transactions',map,where:'id=?',whereArgs:[item.id]);}
  }

  Future<void> delete(int id) async { await (await source.database).delete('transactions',where:'id=?',whereArgs:[id]); }

  Future<Map<String,int>> totals(DateTime from,DateTime to) async {
    final rows=await (await source.database).rawQuery('SELECT type,SUM(amount_minor) total FROM transactions WHERE date_ms>=? AND date_ms<? GROUP BY type',[from.millisecondsSinceEpoch,to.millisecondsSinceEpoch]);
    final result={'profit':0,'loss':0,'expense':0,'income':0};
    for(final row in rows){final type=row['type'] as String;final amount=(row['total'] as int?)??0;result[type]=amount;if(type=='profit')result['income']=amount;}
    return result;
  }

  Future<Map<String,int>> dailyCounts(DateTime day) async {
    final start=DateTime(day.year,day.month,day.day), end=DateTime(day.year,day.month,day.day).add(const Duration(days:1));
    final rows=await (await source.database).rawQuery('SELECT type,COUNT(*) count FROM transactions WHERE date_ms>=? AND date_ms<? GROUP BY type',[start.millisecondsSinceEpoch,end.millisecondsSinceEpoch]);
    final result={'income':0,'expense':0};
    for(final row in rows){final type=row['type'] as String, count=row['count'] as int;if(type=='expense')result['expense']=count;else result['income']=result['income']!+count;}
    return result;
  }

  Future<int> balance(int id,int opening) async {
    final rows=await (await source.database).rawQuery('SELECT type,SUM(amount_minor) total FROM transactions WHERE account_id=? GROUP BY type',[id]);
    var value=opening;
    for(final row in rows){final amount=(row['total'] as int?)??0;value+=row['type']=='profit'?amount:-amount;}
    return value;
  }

  Future<List<Map<String,Object?>>> budgets(String month) async =>
    (await (await source.database).rawQuery("SELECT b.*,c.name category_name,COALESCE((SELECT SUM(t.amount_minor) FROM transactions t WHERE (t.category_id=b.category_id OR t.subcategory_id=b.category_id) AND t.type='expense' AND strftime('%Y-%m',datetime(t.date_ms/1000,'unixepoch','localtime'))=b.month_key),0) spent_minor FROM budgets b JOIN categories c ON c.id=b.category_id WHERE b.month_key=?",[month])).toList();

  Future<void> saveBudget(int categoryId,int amount,String month) async { await (await source.database).insert('budgets',{'category_id':categoryId,'amount_minor':amount,'month_key':month},conflictAlgorithm:ConflictAlgorithm.replace); }

  Future<void> addAccount(String name,String type,int opening) async { await (await source.database).insert('accounts',{'name':name,'type':type,'opening_minor':opening,'created_at':DateTime.now().millisecondsSinceEpoch}); }

  Future<void> addCategory(String name,String type,{int? parentId}) async {
    final db=await source.database;
    if(type=='income' && parentId!=null) throw StateError('Income categories cannot have subcategories.');
    if(parentId!=null){final parent=await db.query('categories',columns:['id','type','parent_id'],where:'id=?',whereArgs:[parentId],limit:1);if(parent.isEmpty||parent.first['type']!='expense'||parent.first['parent_id']!=null)throw StateError('Expense subcategories must belong to a main category.');}
    final duplicate=await db.query('categories',columns:['id'],where:'name=? AND type=? AND parent_id IS ?',whereArgs:[name.trim(),type,parentId],limit:1);
    if(duplicate.isNotEmpty)throw StateError('A category with this name already exists here.');
    final id=await db.insert('categories',{'name':name.trim(),'type':type,'is_default':0,'parent_id':parentId});
    if(type=='expense'&&parentId==null)await db.insert('categories',{'name':'Other','type':'expense','is_default':1,'parent_id':id});
  }

  Future<void> addPaymentMode(String name,{int? parentId}) async {
    final db=await source.database;
    if(parentId!=null){final parent=await db.query('payment_modes',columns:['id','parent_id'],where:'id=?',whereArgs:[parentId],limit:1);if(parent.isEmpty||parent.first['parent_id']!=null)throw StateError('Payment submodes must belong to a main payment mode.');}
    final duplicate=await db.query('payment_modes',columns:['id'],where:'name=? AND parent_id IS ?',whereArgs:[name.trim(),parentId],limit:1);
    if(duplicate.isNotEmpty)throw StateError('A payment mode with this name already exists here.');
    final id=await db.insert('payment_modes',{'name':name.trim(),'parent_id':parentId,'is_default':0});
    if(parentId==null)await db.insert('payment_modes',{'name':'Other','parent_id':id,'is_default':1});
  }

  Future<List<Map<String,Object?>>> recurring() async => (await (await source.database).rawQuery('SELECT r.*,c.name category_name,p.name parent_category_name,a.name account_name FROM recurring r LEFT JOIN categories c ON c.id=r.category_id LEFT JOIN categories p ON p.id=c.parent_id LEFT JOIN accounts a ON a.id=r.account_id ORDER BY r.next_date_ms')).toList();
  Future<void> addRecurring(String title,int amount,String type,int categoryId,int accountId,String frequency,DateTime nextDate) async { await (await source.database).insert('recurring',{'title':title,'amount_minor':amount,'type':type,'category_id':categoryId,'account_id':accountId,'frequency':frequency,'next_date_ms':nextDate.millisecondsSinceEpoch,'is_active':1}); }
  Future<void> toggleRecurring(int id,bool active) async { await (await source.database).update('recurring',{'is_active':active?1:0},where:'id=?',whereArgs:[id]); }
  Future<List<Map<String,Object?>>> goals() async => (await (await source.database).query('goals',orderBy:'id DESC')).toList();
  Future<void> addGoal(String name,int target) async { await (await source.database).insert('goals',{'name':name,'target_minor':target,'saved_minor':0}); }
  Future<void> contributeGoal(int id,int amount) async { await (await source.database).rawUpdate('UPDATE goals SET saved_minor=saved_minor+? WHERE id=?',[amount,id]); }

  Future<List<Map<String,Object?>>> debts() async => (await (await source.database).rawQuery("SELECT *,CASE WHEN remaining_minor<=0 THEN 'paid' ELSE 'unpaid' END status FROM debts ORDER BY date_ms DESC,id DESC")).toList();

  Future<void> addDebt(String person,String direction,int amount,{DateTime? date,String description='',String returnNote='',bool paid=false}) async {
    final normalized=direction=='credit'?'lent':direction=='debit'?'borrowed':direction;
    await (await source.database).insert('debts',{'person':person.trim(),'direction':normalized,'amount_minor':amount,'remaining_minor':paid?0:amount,'date_ms':(date??DateTime.now()).millisecondsSinceEpoch,'description':description.trim(),'return_note':returnNote.trim(),'note':returnNote.trim()});
  }

  Future<void> updateDebt(int id,String person,String direction,int amount,{required DateTime date,required String description,required String returnNote,required bool paid}) async {
    final normalized=direction=='credit'?'lent':direction=='debit'?'borrowed':direction, db=await source.database;
    final old=await db.query('debts',columns:['remaining_minor','amount_minor'],where:'id=?',whereArgs:[id],limit:1);if(old.isEmpty)return;
    final oldAmount=old.first['amount_minor'] as int, oldRemaining=old.first['remaining_minor'] as int;
    final alreadyPaid=(oldAmount-oldRemaining).clamp(0,oldAmount), remaining=paid?0:(oldRemaining<=0?amount:(amount-alreadyPaid).clamp(0,amount));
    await db.update('debts',{'person':person.trim(),'direction':normalized,'amount_minor':amount,'remaining_minor':remaining,'date_ms':date.millisecondsSinceEpoch,'description':description.trim(),'return_note':returnNote.trim(),'note':returnNote.trim()},where:'id=?',whereArgs:[id]);
  }

  Future<void> settleDebt(int id,int amount,{DateTime? date,String note=''}) async {
    final db=await source.database;
    await db.transaction((txn) async {
      final rows=await txn.query('debts',columns:['remaining_minor'],where:'id=?',whereArgs:[id],limit:1);if(rows.isEmpty)return;
      final remaining=rows.first['remaining_minor'] as int;
      if(amount<=0||amount>remaining)throw StateError('Repayment must be greater than zero and no more than the remaining balance.');
      await txn.insert('debt_repayments',{'debt_id':id,'amount_minor':amount,'date_ms':(date??DateTime.now()).millisecondsSinceEpoch,'note':note});
      await txn.update('debts',{'remaining_minor':remaining-amount},where:'id=?',whereArgs:[id]);
    });
  }
  Future<void> deleteDebt(int id) async { await (await source.database).delete('debts',where:'id=?',whereArgs:[id]); }

  Future<List<Map<String,Object?>>> reportCategoryWise({bool subcategory=false,DateTime? from,DateTime? to}) async {
    final clauses=<String>["t.type='expense'"],args=<Object?>[];
    if(from!=null){clauses.add('t.date_ms>=?');args.add(from.millisecondsSinceEpoch);}
    if(to!=null){clauses.add('t.date_ms<?');args.add(to.millisecondsSinceEpoch);}
    final idExpr=subcategory?'t.subcategory_id':'t.category_id';
    return (await source.database).rawQuery('SELECT c.id,c.name,p.name parent_name,SUM(t.amount_minor) total FROM transactions t JOIN categories c ON c.id=$idExpr LEFT JOIN categories p ON p.id=c.parent_id WHERE ${clauses.join(' AND ')} GROUP BY c.id,c.name,p.name ORDER BY total DESC',args);
  }

  Future<List<Map<String,Object?>>> reportPaymentWise({bool submode=false,DateTime? from,DateTime? to}) async {
    final clauses=<String>["t.type='expense'"],args=<Object?>[];
    if(from!=null){clauses.add('t.date_ms>=?');args.add(from.millisecondsSinceEpoch);}
    if(to!=null){clauses.add('t.date_ms<?');args.add(to.millisecondsSinceEpoch);}
    final idExpr=submode?'t.sub_payment_mode_id':'t.payment_mode_id';
    return (await source.database).rawQuery('SELECT c.id,c.name,p.name parent_name,SUM(t.amount_minor) total FROM transactions t JOIN payment_modes c ON c.id=$idExpr LEFT JOIN payment_modes p ON p.id=c.parent_id WHERE ${clauses.join(' AND ')} GROUP BY c.id,c.name,p.name ORDER BY total DESC',args);
  }

  Future<List<Map<String,Object?>>> reportMonthlyWise() async => (await (await source.database).rawQuery("SELECT strftime('%Y-%m',datetime(date_ms/1000,'unixepoch','localtime')) period,SUM(CASE WHEN type='profit' THEN amount_minor ELSE 0 END) profit,SUM(CASE WHEN type='loss' THEN amount_minor ELSE 0 END) loss,SUM(CASE WHEN type='expense' THEN amount_minor ELSE 0 END) expense FROM transactions GROUP BY period ORDER BY period DESC LIMIT 24")).toList();
  Future<List<Map<String,Object?>>> reportQuarterlyWise() async => (await (await source.database).rawQuery("SELECT strftime('%Y',datetime(date_ms/1000,'unixepoch','localtime')) year,CAST((CAST(strftime('%m',datetime(date_ms/1000,'unixepoch','localtime')) AS INTEGER)+2)/3 AS INTEGER) quarter,SUM(CASE WHEN type='profit' THEN amount_minor ELSE 0 END) profit,SUM(CASE WHEN type='loss' THEN amount_minor ELSE 0 END) loss,SUM(CASE WHEN type='expense' THEN amount_minor ELSE 0 END) expense FROM transactions GROUP BY year,quarter ORDER BY year DESC,quarter DESC")).toList();

  Future<Map<String,int>> reportProfitLoss() async {
    final rows=await (await source.database).rawQuery("SELECT type,SUM(amount_minor) total FROM transactions WHERE type IN ('profit','loss') GROUP BY type");
    final result={'profit':0,'loss':0};for(final row in rows){result[row['type'] as String]=(row['total'] as int?)??0;}return result;
  }
  Future<List<Map<String,Object?>>> reportCreditDebitByPerson() async => (await (await source.database).rawQuery("SELECT person,SUM(CASE WHEN direction='lent' THEN amount_minor ELSE 0 END) credit,SUM(CASE WHEN direction='borrowed' THEN amount_minor ELSE 0 END) debit,SUM(CASE WHEN direction='lent' THEN remaining_minor ELSE 0 END) credit_remaining,SUM(CASE WHEN direction='borrowed' THEN remaining_minor ELSE 0 END) debit_remaining FROM debts GROUP BY person COLLATE NOCASE ORDER BY person COLLATE NOCASE")).toList();
  Future<List<Map<String,Object?>>> reportPaidUnpaidByPerson() async => (await (await source.database).rawQuery("SELECT person,SUM(amount_minor-remaining_minor) paid,SUM(remaining_minor) unpaid FROM debts GROUP BY person COLLATE NOCASE ORDER BY person COLLATE NOCASE")).toList();
}
