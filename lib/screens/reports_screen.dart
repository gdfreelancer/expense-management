import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget{const ReportsScreen({super.key});@override State<ReportsScreen> createState()=>_ReportsScreenState();}
class _ReportsScreenState extends State<ReportsScreen>{
  final repo=ExpenseRepository();String selected='main_category';late Future<_ReportData> future;
  final options=<String,String>{'main_category':'Main Category Wise','sub_category':'Sub Category Wise','main_payment':'Main Payment Wise','sub_payment':'Sub Payment Wise','monthly':'Monthly Wise','quarterly':'Quarterly Wise','total_category':'Total Category Wise','profit_loss':'Profit/Loss','credit_debit_person':'Credit/Debit by Person','paid_unpaid_person':'Paid/Unpaid by Person'};
  @override void initState(){super.initState();future=load();}
  Future<_ReportData> load() async{
    final now=DateTime.now();
    final from=DateTime(now.year,now.month);
    final to=DateTime(now.year,now.month+1);
    switch(selected){
      case 'main_category':return _ReportData(rows:await repo.reportCategoryWise(from:from,to:to),kind:'category');
      case 'sub_category':return _ReportData(rows:await repo.reportCategoryWise(subcategory:true,from:from,to:to),kind:'subcategory');
      case 'main_payment':return _ReportData(rows:await repo.reportPaymentWise(from:from,to:to),kind:'payment');
      case 'sub_payment':return _ReportData(rows:await repo.reportPaymentWise(submode:true,from:from,to:to),kind:'subpayment');
      case 'monthly':return _ReportData(rows:await repo.reportMonthlyWise(),kind:'monthly');
      case 'quarterly':return _ReportData(rows:await repo.reportQuarterlyWise(),kind:'quarterly');
      case 'total_category':return _ReportData(rows:await repo.reportCategoryWise(),kind:'category');
      case 'profit_loss':final v=await repo.reportProfitLoss();return _ReportData(rows:[{'profit':v['profit'],'loss':v['loss']}],kind:'profit_loss');
      case 'credit_debit_person':return _ReportData(rows:await repo.reportCreditDebitByPerson(),kind:'credit_debit');
      default:return _ReportData(rows:await repo.reportPaidUnpaidByPerson(),kind:'paid_unpaid');
    }
  }
  void select(String? value){if(value!=null)setState((){selected=value;future=load();});}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(context.tr('Reports'))),body:FutureBuilder<_ReportData>(future:future,builder:(context,snapshot){
    if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    if(snapshot.hasError)return Center(child:Text(context.tr('Unable to load report.')));
    final data=snapshot.data!;
    final rows=data.rows;
    return ListView(padding:const EdgeInsets.fromLTRB(16,8,16,20),children:[
      DropdownButtonFormField<String>(value:selected,isExpanded:true,decoration:InputDecoration(labelText:context.tr('Select report')),items:options.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(context.tr(e.value)))).toList(),onChanged:select),
      const SizedBox(height:8),
      if(selected!='monthly'&&selected!='quarterly'&&selected!='total_category'&&selected!='profit_loss'&&selected!='credit_debit_person'&&selected!='paid_unpaid_person')Text(context.tr('Showing this month'),style:const TextStyle(color:AppTheme.muted,fontSize:11)),
      if(rows.isEmpty)Container(margin:const EdgeInsets.only(top:14),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:AppTheme.border),borderRadius:BorderRadius.circular(14)),child:Text(context.tr('No data available for this report.')))
      else ...rows.map((row)=>_row(data.kind,row)),
    ]);
  }));
  Widget _row(String kind,Map<String,Object?> row){
    if(kind=='profit_loss'){
      final profit=(row['profit'] as int? ??0),loss=(row['loss'] as int? ??0);
      return Container(margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:AppTheme.border),borderRadius:BorderRadius.circular(14)),child:Column(children:[
        _amountLine(context.tr('Total Profit'),profit,AppTheme.income),const Divider(height:18),_amountLine(context.tr('Total Loss'),loss,AppTheme.expense),const Divider(height:18),_amountLine(context.tr('Net Profit'),profit-loss,profit>=loss?AppTheme.income:AppTheme.expense),
      ]));
    }
    String title='';
    if(kind=='category'||kind=='payment'||kind=='subpayment'||kind=='subcategory'){title=(row['parent_name'] as String?)==null?(row['name'] as String? ??''):'${row['parent_name']}  ›  ${row['name']}';}
    if(kind=='monthly')title=row['period'] as String? ??'';
    if(kind=='quarterly')title='${row['year']} · Q${row['quarter']}';
    if(kind=='credit_debit'||kind=='paid_unpaid')title=row['person'] as String? ??'';
    final amount=(row['total'] as int? ??0);
    return Container(margin:const EdgeInsets.only(top:9),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:AppTheme.border),borderRadius:BorderRadius.circular(13)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800,color:AppTheme.ink)),
      const SizedBox(height:8),
      if(kind=='monthly'||kind=='quarterly')...[
        _amountLine(context.tr('Profit'),row['profit'] as int? ??0,AppTheme.income),
        _amountLine(context.tr('Loss'),row['loss'] as int? ??0,AppTheme.expense),
        _amountLine(context.tr('Expense'),row['expense'] as int? ??0,AppTheme.expense),
      ]else if(kind=='credit_debit')...[
        _amountLine(context.tr('Credit'),row['credit'] as int? ??0,AppTheme.income),
        _amountLine(context.tr('Debit'),row['debit'] as int? ??0,AppTheme.expense),
        Text('${context.tr('Outstanding')}: ${Fmt.money(((row['credit_remaining'] as int? ??0)+(row['debit_remaining'] as int? ??0))/100)}',style:const TextStyle(fontSize:11,color:AppTheme.muted)),
      ]else if(kind=='paid_unpaid')...[
        _amountLine(context.tr('Paid'),row['paid'] as int? ??0,AppTheme.income),
        _amountLine(context.tr('Unpaid'),row['unpaid'] as int? ??0,AppTheme.expense),
      ]else _amountLine(context.tr('Total'),amount,AppTheme.brand),
    ]));
  }
  Widget _amountLine(String label,int minor,Color color)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[Expanded(child:Text(label,style:const TextStyle(color:AppTheme.muted,fontSize:11))),Text(Fmt.money(minor/100),style:TextStyle(color:color,fontSize:13,fontWeight:FontWeight.w800))]));
}
class _ReportData{_ReportData({required this.rows,required this.kind});final List<Map<String,Object?>> rows;final String kind;}
