import 'package:flutter/material.dart';
import '../core/extensions/iterable_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key,required this.onAdd,required this.onSeeAll});final VoidCallback onAdd,onSeeAll;
  @override State<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen>{
  final repo=ExpenseRepository();late Future<_Data> future;
  @override void initState(){super.initState();future=load();}
  Future<_Data> load() async{
    final now=DateTime.now();
    final start=DateTime(now.year,now.month);
    final prefs=await SharedPreferences.getInstance();
    return _Data(await repo.totals(start,DateTime(now.year,now.month+1)),(await repo.transactions()).take(6).toList(),await repo.categories(),await repo.accounts(),await repo.dailyCounts(now),await repo.dailyCounts(now.subtract(const Duration(days:1))),prefs.getString('profile_name')??'');
  }
  Future<void> showAddOptions() async{
    final value=await showModalBottomSheet<String>(context:context,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
      ListTile(leading:const Icon(Icons.north_east_rounded,color:AppTheme.expense),title:Text(context.tr('Add expense')),onTap:()=>Navigator.pop(ctx,'expense')),
      ListTile(leading:const Icon(Icons.south_west_rounded,color:AppTheme.income),title:Text(context.tr('Add income')),onTap:()=>Navigator.pop(ctx,'income')),
      const SizedBox(height:8),
    ])));
    if(value==null||!mounted)return;
    if(value=='expense'){widget.onAdd();}else{await Navigator.push(context,MaterialPageRoute(builder:(_)=>AddTransactionScreen(initialType:'income',onSaved:()=>setState(()=>future=load()))));}
    if(mounted)setState(()=>future=load());
  }
  @override Widget build(BuildContext context)=>Scaffold(
    body:SafeArea(child:FutureBuilder<_Data>(future:future,builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError)return Center(child:Text(context.tr('Unable to load dashboard.')));
      final data=snapshot.data!;
      final profit=data.totals['profit']??0;
      final loss=data.totals['loss']??0;
      final income=profit-loss;
      final expense=data.totals['expense']??0;
      String category(int id)=>data.categories.where((e)=>e['id']==id).map((e)=>e['name'] as String).firstOrNull??context.tr('Other');
      String account(int id)=>data.accounts.where((e)=>e['id']==id).map((e)=>e['name'] as String).firstOrNull??context.tr('Account');
      return RefreshIndicator(onRefresh:()async=>setState(()=>future=load()),child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(18,12,18,90),children:[
        Text(data.profileName.isEmpty?context.tr('Welcome'):data.profileName,style:Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height:4),Text(context.tr('Your money overview'),style:const TextStyle(color:AppTheme.muted,fontSize:12)),
        const SizedBox(height:18),
        Row(children:[
          Expanded(child:_MetricCard(label:context.tr('Income'),amount:income,color:income>=0?AppTheme.income:AppTheme.expense,icon:Icons.south_west_rounded,today:data.today['income']??0,yesterday:data.yesterday['income']??0)),
          const SizedBox(width:10),
          Expanded(child:_MetricCard(label:context.tr('Expense'),amount:expense,color:AppTheme.expense,icon:Icons.north_east_rounded,today:data.today['expense']??0,yesterday:data.yesterday['expense']??0)),
        ]),
        const SizedBox(height:20),
        Row(children:[Text(context.tr('Recent activity'),style:Theme.of(context).textTheme.titleLarge),const Spacer(),TextButton(onPressed:widget.onSeeAll,child:Text(context.tr('See all')))]),
        if(data.items.isEmpty)Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:AppTheme.border)),child:Text(context.tr('No transactions yet. Add your first one.'),style:const TextStyle(color:AppTheme.muted,fontSize:12)))
        else Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:3),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:AppTheme.border)),child:Column(children:[for(var i=0;i<data.items.length;i++)...[
          TransactionTile(item:data.items[i],category:category(data.items[i].subcategoryId??data.items[i].categoryId),account:account(data.items[i].accountId)),
          if(i!=data.items.length-1)const Divider(indent:50,height:1),
        ]])),
      ]));
    })),
    floatingActionButton:FloatingActionButton.extended(onPressed:showAddOptions,icon:const Icon(Icons.add_rounded),label:Text(context.tr('Add transaction'))),
  );
}

class _MetricCard extends StatelessWidget{
  const _MetricCard({required this.label,required this.amount,required this.color,required this.icon,required this.today,required this.yesterday});
  final String label;final int amount,today,yesterday;final Color color;final IconData icon;
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:AppTheme.border),borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Icon(icon,color:color,size:16),const SizedBox(width:6),Text(label,style:const TextStyle(color:AppTheme.muted,fontSize:11,fontWeight:FontWeight.w700))]),
    const SizedBox(height:8),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(Fmt.money(amount/100),style:TextStyle(color:color,fontSize:20,fontWeight:FontWeight.w800))),
    const SizedBox(height:8),Text('${context.tr('Today')}: $today',style:const TextStyle(color:AppTheme.ink,fontSize:10,fontWeight:FontWeight.w600)),
    const SizedBox(height:3),Text('${context.tr('Yesterday')}: $yesterday',style:const TextStyle(color:AppTheme.muted,fontSize:10)),
  ]));
}
class _Data{
  _Data(this.totals,this.items,this.categories,this.accounts,this.today,this.yesterday,this.profileName);
  final Map<String,int> totals;final List items;final List<Map<String,Object?>> categories,accounts;final Map<String,int> today,yesterday;final String profileName;
}
