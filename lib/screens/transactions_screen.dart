import 'package:flutter/material.dart';
import '../core/extensions/iterable_extensions.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/expense_transaction.dart';
import 'add_transaction_screen.dart';
import 'credit_debit_form_screen.dart';

class TransactionsScreen extends StatefulWidget{
  const TransactionsScreen({super.key,required this.onChanged});final VoidCallback onChanged;
  @override State<TransactionsScreen> createState()=>_TransactionsScreenState();
}
class _TransactionsScreenState extends State<TransactionsScreen>{
  final repo=ExpenseRepository();String filter='all',query='';late Future<_Data> future;
  @override void initState(){super.initState();future=load();}
  Future<_Data> load() async=>_Data(await repo.transactions(),await repo.categories(),await repo.accounts(),await repo.paymentModes(),await repo.debts());
  void reload()=>setState(()=>future=load());

  Future<void> search() async{
    final c=TextEditingController(text:query);
    final v=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:Text(context.tr('Search activity')),content:TextField(controller:c,autofocus:true,decoration:InputDecoration(hintText:context.tr('Search by description or person'),prefixIcon:const Icon(Icons.search))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(context.tr('Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text),child:Text(context.tr('Search')))]));
    if(v!=null&&mounted)setState(()=>query=v);c.dispose();
  }
  Future<void> addChoice() async{
    final choice=await showModalBottomSheet<String>(context:context,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
      ListTile(leading:const Icon(Icons.north_east_rounded,color:AppTheme.expense),title:Text(context.tr('Add expense')),onTap:()=>Navigator.pop(ctx,'expense')),
      ListTile(leading:const Icon(Icons.south_west_rounded,color:AppTheme.income),title:Text(context.tr('Add income')),onTap:()=>Navigator.pop(ctx,'income')),
      ListTile(leading:const Icon(Icons.people_alt_outlined,color:AppTheme.brand),title:Text(context.tr('Add Credit/Debit')),onTap:()=>Navigator.pop(ctx,'debt')),
      const SizedBox(height:8),
    ])));
    if(choice==null||!mounted)return;
    if(choice=='debt'){await Navigator.push(context,MaterialPageRoute(builder:(_)=>CreditDebitFormScreen(onSaved:widget.onChanged)));}
    else{await Navigator.push(context,MaterialPageRoute(builder:(_)=>AddTransactionScreen(initialType:choice,onSaved:widget.onChanged)));}
    if(mounted)reload();
  }
  Future<void> editTransaction(ExpenseTransaction item) async{
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>AddTransactionScreen(initialType:item.type,item:item,onSaved:widget.onChanged)));
    if(mounted)reload();
  }
  Future<void> editDebt(Map<String,Object?> item) async{
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>CreditDebitFormScreen(item:item,onSaved:widget.onChanged)));
    if(mounted)reload();
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(context.tr('Activity')),actions:[IconButton(onPressed:search,icon:const Icon(Icons.search_rounded))]),
    floatingActionButton:FloatingActionButton.extended(onPressed:addChoice,icon:const Icon(Icons.add_rounded),label:Text(context.tr('Add'))),
    body:FutureBuilder<_Data>(future:future,builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError)return Center(child:Text(context.tr('Unable to load activity.')));
      final data=snapshot.data!;
      final transactions=data.transactions.where((e){
        if(filter=='expense'&&e.type!='expense')return false;
        if(filter=='profit_loss'&&e.type=='expense')return false;
        if(filter=='credit_debit')return false;
        return e.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
      final debts=filter=='all'||filter=='credit_debit'?data.debts.where((e)=>'${e['person']} ${e['description']} ${e['return_note']}'.toLowerCase().contains(query.toLowerCase())).toList():<Map<String,Object?>>[];
      final entries=<_Entry>[
        ...transactions.map((e)=>_Entry(date:e.date,isDebt:false,transaction:e)),
        ...debts.map((e)=>_Entry(date:DateTime.fromMillisecondsSinceEpoch(e['date_ms'] as int? ??0),isDebt:true,debt:e)),
      ]..sort((a,b)=>b.date.compareTo(a.date));
      String category(int id)=>data.categories.where((e)=>e['id']==id).map((e)=>e['name'] as String).firstOrNull??context.tr('Other');
      String account(int id)=>data.accounts.where((e)=>e['id']==id).map((e)=>e['name'] as String).firstOrNull??context.tr('Account');
      String mode(int? id)=>data.paymentModes.where((e)=>e['id']==id).map((e)=>e['name'] as String).firstOrNull??'';
      return Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(12,8,12,10),child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          _filterChip(context,'all','ALL'),_filterChip(context,'expense','Expense'),_filterChip(context,'profit_loss','Profit/Loss'),_filterChip(context,'credit_debit','Credit/Debit'),
        ]))),
        Expanded(child:entries.isEmpty?Center(child:Text(context.tr('No matching activity'))):ListView.separated(padding:const EdgeInsets.fromLTRB(16,0,16,90),itemCount:entries.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(ctx,index){
          final entry=entries[index];
          final key=entry.isDebt?'debt-${entry.debt!['id']}':'transaction-${entry.transaction!.id}';
          return Dismissible(key:ValueKey(key),direction:DismissDirection.endToStart,background:Container(alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:20),color:Colors.red.shade50,child:const Icon(Icons.delete_outline,color:Colors.red)),confirmDismiss:(_)=>_confirmDelete(ctx),onDismissed:(_) async {if(entry.isDebt){await repo.deleteDebt(entry.debt!['id'] as int);}else{await repo.delete(entry.transaction!.id!);}widget.onChanged();if(mounted)reload();},
            child:entry.isDebt?_debtTile(entry.debt!,()=>editDebt(entry.debt!)): _transactionTile(entry.transaction!,category,account,mode,()=>editTransaction(entry.transaction!)));
        })),
      ]);
    }),
  );

  Widget _filterChip(BuildContext context,String value,String label)=>Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(label),selected:filter==value,onSelected:(_){setState((){filter=value;future=load();});}));
  Future<bool> _confirmDelete(BuildContext ctx) async=>await showDialog<bool>(context:ctx,builder:(d)=>AlertDialog(title:Text(context.tr('Delete record?')),content:Text(context.tr('This record will be permanently deleted.')),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:Text(context.tr('Cancel'))),FilledButton(onPressed:()=>Navigator.pop(d,true),child:Text(context.tr('Delete')))]))??false;

  Widget _transactionTile(ExpenseTransaction item,String Function(int) category,String Function(int) account,String Function(int?) mode,VoidCallback onTap){
    final profit=item.type=='profit';
    final loss=item.type=='loss';
    final color=profit?AppTheme.income:AppTheme.expense;
    final type=profit?context.tr('Profit'):loss?context.tr('Loss'):context.tr('Expense');
    final categoryLabel=item.type=='expense'?'${category(item.categoryId)}  ›  ${category(item.subcategoryId??item.categoryId)}':category(item.categoryId);
    final paymentLabel=item.type=='expense'?' · ${mode(item.paymentModeId)}  ›  ${mode(item.subPaymentModeId)}':'';
    return ListTile(onTap:onTap,contentPadding:const EdgeInsets.symmetric(horizontal:2,vertical:3),leading:CircleAvatar(backgroundColor:color.withValues(alpha:.1),child:Icon(profit?Icons.south_west_rounded:Icons.north_east_rounded,color:color)),title:Text(item.title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('$type · $categoryLabel · ${account(item.accountId)}$paymentLabel\n${Fmt.activityDate(item.date)}',maxLines:2),isThreeLine:true,trailing:Text('${profit?'+':'−'}${Fmt.money(item.amountMinor/100)}',style:TextStyle(color:color,fontWeight:FontWeight.w800)));
  }
  Widget _debtTile(Map<String,Object?> item,VoidCallback onTap){
    final credit=item['direction']=='lent';
    final paid=item['remaining_minor']==0;
    final color=credit?AppTheme.income:AppTheme.expense;
    return ListTile(onTap:onTap,contentPadding:const EdgeInsets.symmetric(horizontal:2,vertical:3),leading:CircleAvatar(backgroundColor:color.withValues(alpha:.1),child:Icon(Icons.people_alt_outlined,color:color)),title:Text((item['description'] as String?)?.isNotEmpty==true?item['description'] as String:item['person'] as String,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${credit?context.tr('Credit'):context.tr('Debit')} · ${item['person']} · ${paid?context.tr('Paid'):context.tr('Unpaid')}\n${Fmt.activityDate(DateTime.fromMillisecondsSinceEpoch(item['date_ms'] as int? ??0))}',maxLines:2),isThreeLine:true,trailing:Text(Fmt.money((item['amount_minor'] as int)/100),style:TextStyle(color:color,fontWeight:FontWeight.w800)));
  }
}
class _Data{_Data(this.transactions,this.categories,this.accounts,this.paymentModes,this.debts);final List<ExpenseTransaction> transactions;final List<Map<String,Object?>> categories,accounts,paymentModes,debts;}
class _Entry{_Entry({required this.date,required this.isDebt,this.transaction,this.debt});final DateTime date;final bool isDebt;final ExpenseTransaction? transaction;final Map<String,Object?>? debt;}
