import 'package:flutter/material.dart';import '../core/utils/formatters.dart';import '../models/expense_transaction.dart';
class TransactionTile extends StatelessWidget{
 const TransactionTile({super.key,required this.item,required this.category,required this.account,this.onTap});final ExpenseTransaction item;final String category,account;final VoidCallback? onTap;
 @override Widget build(BuildContext context){final income=item.type=='income';return ListTile(onTap:onTap,leading:CircleAvatar(backgroundColor:(income?Colors.green:Colors.deepOrange).withValues(alpha:.12),child:Icon(income?Icons.south_west:Icons.north_east,color:income?Colors.green:Colors.deepOrange)),title:Text(item.title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('$category • $account'),trailing:Text((income?'+':'-')+Fmt.money(item.amountMinor/100),style:TextStyle(fontWeight:FontWeight.w800,color:income?Colors.green:Colors.black87)));}
}
