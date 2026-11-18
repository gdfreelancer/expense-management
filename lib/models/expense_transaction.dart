class ExpenseTransaction{
 final int? id;final String title,type,note;final int amountMinor,categoryId,accountId;final DateTime date;
 const ExpenseTransaction({this.id,required this.title,required this.type,required this.amountMinor,required this.categoryId,required this.accountId,required this.date,this.note=''});
 factory ExpenseTransaction.fromMap(Map<String,Object?> m)=>ExpenseTransaction(id:m['id'] as int,title:m['title'] as String,type:m['type'] as String,amountMinor:m['amount_minor'] as int,categoryId:m['category_id'] as int,accountId:m['account_id'] as int,date:DateTime.fromMillisecondsSinceEpoch(m['date_ms'] as int),note:(m['note'] as String?)??'');
 Map<String,Object?> toMap()=>{'title':title,'type':type,'amount_minor':amountMinor,'category_id':categoryId,'account_id':accountId,'date_ms':date.millisecondsSinceEpoch,'note':note};
}
