import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/expense_repository.dart';
import '../l10n/app_localizations.dart';

class PaymentModesScreen extends StatefulWidget{const PaymentModesScreen({super.key});@override State<PaymentModesScreen> createState()=>_PaymentModesScreenState();}
class _PaymentModesScreenState extends State<PaymentModesScreen>{
  final repo=ExpenseRepository();late Future<List<Map<String,Object?>>> future;
  @override void initState(){super.initState();future=repo.paymentModes();}
  void reload()=>setState(()=>future=repo.paymentModes());
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(context.tr('Payment Modes'))),floatingActionButton:FloatingActionButton.extended(onPressed:()=>add(),icon:const Icon(Icons.add_rounded),label:Text(context.tr('Add payment mode'))),body:FutureBuilder<List<Map<String,Object?>>>(future:future,builder:(context,snapshot){
    if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    final rows=snapshot.data??[],roots=rows.where((e)=>e['parent_id']==null).toList();
    return ListView(padding:const EdgeInsets.fromLTRB(16,8,16,90),children:[
      Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppTheme.softGreen,borderRadius:BorderRadius.circular(13)),child:Text(context.tr('Choose a main payment mode and organise its payment options underneath.'),style:const TextStyle(color:AppTheme.brandDark,fontSize:12))),
      const SizedBox(height:12),
      ...roots.map((root){final children=rows.where((e)=>e['parent_id']==root['id']).toList();return Container(margin:const EdgeInsets.only(bottom:9),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:AppTheme.border),borderRadius:BorderRadius.circular(14)),child:Column(children:[
        ListTile(leading:const Icon(Icons.account_balance_wallet_outlined,color:AppTheme.brand),title:Text(root['name'] as String,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${children.length} ${context.tr('sub payment modes')}'),trailing:IconButton(onPressed:()=>add(parent:root),icon:const Icon(Icons.add_circle_outline_rounded,color:AppTheme.brand))),
        if(children.isNotEmpty)const Divider(height:1),...children.map((child)=>Padding(padding:const EdgeInsets.fromLTRB(18,0,12,0),child:ListTile(dense:true,leading:const Icon(Icons.subdirectory_arrow_right_rounded,size:18,color:AppTheme.muted),title:Text(child['name'] as String,style:const TextStyle(fontSize:13))))),
      ]));}),
    ]);
  }));
  Future<void> add({Map<String,Object?>? parent}) async{
    final name=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(parent==null?context.tr('New main payment mode'):context.tr('New sub payment mode')),content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(parent!=null)Padding(padding:const EdgeInsets.only(bottom:9),child:Text('${context.tr('Under')}: ${parent['name']}',style:const TextStyle(color:AppTheme.muted,fontSize:12))),
      TextField(controller:name,autofocus:true,textCapitalization:TextCapitalization.words,decoration:InputDecoration(labelText:context.tr('Payment mode name'))),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(context.tr('Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(context.tr('Save')))]));
    if(ok==true&&name.text.trim().isNotEmpty){try{await repo.addPaymentMode(name.text.trim(),parentId:parent?['id'] as int?);if(mounted)reload();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Bad state: ',''))));}}
    name.dispose();
  }
}
