import 'package:flutter/material.dart';
import '../core/utils/currency_data.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../l10n/app_localizations.dart';

class CreditDebitFormScreen extends StatefulWidget{
  const CreditDebitFormScreen({super.key,this.item,required this.onSaved});
  final Map<String,Object?>? item;final VoidCallback onSaved;
  @override State<CreditDebitFormScreen> createState()=>_CreditDebitFormScreenState();
}
class _CreditDebitFormScreenState extends State<CreditDebitFormScreen>{
  final repo=ExpenseRepository();final person=TextEditingController(),amount=TextEditingController(),description=TextEditingController(),returnNote=TextEditingController();
  String direction='credit',status='unpaid';DateTime date=DateTime.now();bool saving=false;
  @override void initState(){super.initState();final item=widget.item;if(item!=null){
    person.text=(item['person'] as String?)??'';amount.text=((item['amount_minor'] as int? ??0)/100).toStringAsFixed(2);
    description.text=(item['description'] as String?)??'';returnNote.text=(item['return_note'] as String?)??(item['note'] as String? ??'');
    direction=item['direction']=='borrowed'?'debit':'credit';status=(item['remaining_minor'] as int? ??0)==0?'paid':'unpaid';
    date=DateTime.fromMillisecondsSinceEpoch(item['date_ms'] as int? ??DateTime.now().millisecondsSinceEpoch);
  }}
  Future<void> chooseDate() async{final v=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(v!=null&&mounted)setState(()=>date=v);}
  Future<void> save() async{
    final parsed=Fmt.parseAmount(amount.text);if(person.text.trim().isEmpty||description.text.trim().isEmpty||parsed==null||parsed<=0){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(context.tr('Please complete all required fields.'))));return;}
    setState(()=>saving=true);
    try{final minor=(parsed*100).round();
      final id=widget.item?['id'] as int?;
      if(id==null){await repo.addDebt(person.text.trim(),direction,minor,date:date,description:description.text.trim(),returnNote:returnNote.text.trim(),paid:status=='paid');}
      else{await repo.updateDebt(id,person.text.trim(),direction,minor,date:date,description:description.text.trim(),returnNote:returnNote.text.trim(),paid:status=='paid');}
      widget.onSaved();if(mounted)Navigator.pop(context);
    }catch(e){if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Bad state: ',''))));}}
  }
  @override void dispose(){person.dispose();amount.dispose();description.dispose();returnNote.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.item==null?context.tr('New Credit/Debit'):context.tr('Edit Credit/Debit'))),body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,22),children:[
    ListTile(contentPadding:EdgeInsets.zero,title:Text(context.tr('Date')),subtitle:Text(Fmt.activityDate(date)),trailing:const Icon(Icons.calendar_month_rounded),onTap:chooseDate),
    const SizedBox(height:8),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),style:const TextStyle(fontSize:26,fontWeight:FontWeight.w800),decoration:InputDecoration(labelText:context.tr('Amount'),prefixText:'${CurrencySettings.selected.symbol} ')),
    const SizedBox(height:13),TextField(controller:description,textCapitalization:TextCapitalization.sentences,decoration:InputDecoration(labelText:context.tr('Description'))),
    const SizedBox(height:13),TextField(controller:returnNote,maxLines:2,decoration:InputDecoration(labelText:context.tr('Return Note (optional)'))),
    const SizedBox(height:13),TextField(controller:person,textCapitalization:TextCapitalization.words,decoration:InputDecoration(labelText:context.tr('Person'))),
    const SizedBox(height:15),Text(context.tr('Type'),style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:7),
    SegmentedButton<String>(segments:[ButtonSegment(value:'credit',label:Text(context.tr('Credit · Money lent'))),ButtonSegment(value:'debit',label:Text(context.tr('Debit · Money borrowed')))],selected:{direction},onSelectionChanged:(v)=>setState(()=>direction=v.first)),
    const SizedBox(height:15),Text(context.tr('Status'),style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:7),
    SegmentedButton<String>(segments:[ButtonSegment(value:'paid',label:Text(context.tr('Paid'))),ButtonSegment(value:'unpaid',label:Text(context.tr('Unpaid')))],selected:{status},onSelectionChanged:(v)=>setState(()=>status=v.first)),
    const SizedBox(height:20),FilledButton(onPressed:saving?null:save,child:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(context.tr('Save record'))),
  ]));
}
