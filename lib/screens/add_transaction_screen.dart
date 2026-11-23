import 'package:flutter/material.dart';
import '../core/utils/currency_data.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/expense_transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key,this.initialType='expense',this.item,required this.onSaved});
  final String initialType; final ExpenseTransaction? item; final VoidCallback onSaved;
  @override State<AddTransactionScreen> createState()=>_AddTransactionScreenState();
}
class _AddTransactionScreenState extends State<AddTransactionScreen>{
  final repo=ExpenseRepository();
  final titleController=TextEditingController(),amountController=TextEditingController(),noteController=TextEditingController();
  String type='expense'; DateTime date=DateTime.now();
  int? categoryId,subcategoryId,paymentModeId,subPaymentModeId,accountId;
  List<Map<String,Object?>> categories=[],accounts=[],paymentModes=[];
  bool busy=true,saving=false;
  bool get isExpense=>type=='expense';
  List<Map<String,Object?>> get mainCategories=>categories.where((e)=>e['parent_id']==null).toList();
  List<Map<String,Object?>> get subcategories=>categories.where((e)=>e['parent_id']==categoryId).toList();
  List<Map<String,Object?>> get mainPaymentModes=>paymentModes.where((e)=>e['parent_id']==null).toList();
  List<Map<String,Object?>> get subPaymentModes=>paymentModes.where((e)=>e['parent_id']==paymentModeId).toList();
  @override void initState(){super.initState();final item=widget.item;type=item?.type??(widget.initialType=='income'?'profit':widget.initialType);date=item?.date??DateTime.now();titleController.text=item?.title??'';amountController.text=item==null?'':(item.amountMinor/100).toStringAsFixed(2);noteController.text=item?.note??'';categoryId=item?.categoryId;subcategoryId=item?.subcategoryId;paymentModeId=item?.paymentModeId;subPaymentModeId=item?.subPaymentModeId;accountId=item?.accountId;load();}
  Future<void> load() async {
    try{final values=await Future.wait([repo.categories(type:isExpense?'expense':'income'),repo.accounts(),repo.paymentModes()]);if(!mounted)return;setState((){
      categories=values[0] as List<Map<String,Object?>>;accounts=values[1] as List<Map<String,Object?>>;paymentModes=values[2] as List<Map<String,Object?>>;
      categoryId??=mainCategories.isEmpty?null:mainCategories.first['id'] as int;
      if(isExpense){subcategoryId??=subcategories.isEmpty?null:subcategories.first['id'] as int;paymentModeId??=mainPaymentModes.isEmpty?null:mainPaymentModes.first['id'] as int;subPaymentModeId??=subPaymentModes.isEmpty?null:subPaymentModes.first['id'] as int;}
      accountId??=accounts.isEmpty?null:accounts.first['id'] as int;busy=false;
    });}catch(_){if(mounted)setState(()=>busy=false);}
  }
  void selectCategory(int? v){setState((){categoryId=v;subcategoryId=subcategories.isEmpty?null:subcategories.first['id'] as int;});}
  void selectPaymentMode(int? v){setState((){paymentModeId=v;subPaymentModeId=subPaymentModes.isEmpty?null:subPaymentModes.first['id'] as int;});}
  Future<void> chooseDate() async{final v=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(v!=null&&mounted)setState(()=>date=v);}
  Future<void> save() async{
    final amount=Fmt.parseAmount(amountController.text);
    if(titleController.text.trim().isEmpty||amount==null||amount<=0||categoryId==null||accountId==null||(isExpense&&(subcategoryId==null||paymentModeId==null||subPaymentModeId==null))){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(context.tr('Please complete all required fields.'))));return;}
    setState(()=>saving=true);
    try{await repo.save(ExpenseTransaction(id:widget.item?.id,title:titleController.text.trim(),type:type,amountMinor:(amount*100).round(),categoryId:categoryId!,subcategoryId:isExpense?subcategoryId:null,paymentModeId:isExpense?paymentModeId:null,subPaymentModeId:isExpense?subPaymentModeId:null,accountId:accountId!,date:date,note:noteController.text.trim()));widget.onSaved();if(mounted)Navigator.pop(context);}
    catch(e){if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Bad state: ',''))));}}
  }
  @override void dispose(){titleController.dispose();amountController.dispose();noteController.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final incomeGroup=!isExpense;
    return Scaffold(appBar:AppBar(title:Text(widget.item==null?(isExpense?context.tr('New expense'):context.tr('New income')):context.tr('Edit transaction'))),
      body:busy?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.fromLTRB(16,12,16,22),children:[
        if(incomeGroup)...[Text(context.tr('Type'),style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:7),SegmentedButton<String>(segments:[ButtonSegment(value:'profit',label:Text(context.tr('Profit'))),ButtonSegment(value:'loss',label:Text(context.tr('Loss')))],selected:{type},onSelectionChanged:(v)=>setState(()=>type=v.first)),const SizedBox(height:14)],
        TextField(controller:amountController,keyboardType:const TextInputType.numberWithOptions(decimal:true),style:const TextStyle(fontSize:27,fontWeight:FontWeight.w800),decoration:InputDecoration(labelText:context.tr('Amount'),prefixText:'${CurrencySettings.selected.symbol} ')),
        const SizedBox(height:13),TextField(controller:titleController,textCapitalization:TextCapitalization.sentences,decoration:InputDecoration(labelText:context.tr('Description'))),
        const SizedBox(height:13),ListTile(contentPadding:EdgeInsets.zero,title:Text(context.tr('Date')),subtitle:Text(Fmt.activityDate(date)),trailing:const Icon(Icons.calendar_month_rounded),onTap:chooseDate),
        const SizedBox(height:7),DropdownButtonFormField<int>(value:categoryId,isExpanded:true,decoration:InputDecoration(labelText:context.tr(isExpense?'Main Category':'Category')),items:mainCategories.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text(context.tr(e['name'] as String)))).toList(),onChanged:selectCategory),
        if(isExpense)...[
          const SizedBox(height:13),DropdownButtonFormField<int>(value:subcategoryId,isExpanded:true,decoration:InputDecoration(labelText:context.tr('Sub Category')),items:subcategories.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text(context.tr(e['name'] as String)))).toList(),onChanged:(v)=>setState(()=>subcategoryId=v)),
          const SizedBox(height:13),DropdownButtonFormField<int>(value:paymentModeId,isExpanded:true,decoration:InputDecoration(labelText:context.tr('Main Payment Mode')),items:mainPaymentModes.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text(e['name'] as String))).toList(),onChanged:selectPaymentMode),
          const SizedBox(height:13),DropdownButtonFormField<int>(value:subPaymentModeId,isExpanded:true,decoration:InputDecoration(labelText:context.tr('Sub Payment Mode')),items:subPaymentModes.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text(e['name'] as String))).toList(),onChanged:(v)=>setState(()=>subPaymentModeId=v)),
        ],
        const SizedBox(height:13),DropdownButtonFormField<int>(value:accountId,isExpanded:true,decoration:InputDecoration(labelText:context.tr('Account')),items:accounts.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text(e['name'] as String))).toList(),onChanged:(v)=>setState(()=>accountId=v)),
        const SizedBox(height:13),TextField(controller:noteController,maxLines:2,decoration:InputDecoration(labelText:context.tr('Note (optional)'))),
        const SizedBox(height:20),FilledButton(onPressed:saving?null:save,child:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(context.tr('Save transaction'))),
      ]));
  }
}
