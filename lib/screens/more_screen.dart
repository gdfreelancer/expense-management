import 'package:flutter/material.dart';import 'accounts_screen.dart';import 'categories_screen.dart';import 'settings_screen.dart';import 'recurring_screen.dart';import 'goals_screen.dart';import 'debts_screen.dart';
class MoreScreen extends StatelessWidget{const MoreScreen({super.key,required this.onChanged});final VoidCallback onChanged;@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('More')),body:ListView(padding:const EdgeInsets.all(18),children:[
 _item(context,Icons.account_balance_wallet,'Accounts','Manage cash and bank accounts',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AccountsScreen(onChanged:onChanged)))),
 _item(context,Icons.category,'Categories','Customise income and expense types',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CategoriesScreen(onChanged:onChanged)))),
 _item(context,Icons.autorenew,'Recurring','Track bills and repeating income',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RecurringScreen()))),
 _item(context,Icons.flag_outlined,'Savings goals','Track progress towards a target',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const GoalsScreen()))),
 _item(context,Icons.handshake_outlined,'Debt tracker','Money lent and borrowed',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const DebtsScreen()))),
 _item(context,Icons.settings,'Settings','App preferences and privacy',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsScreen()))),
 const SizedBox(height:20),const Card(child:ListTile(leading:Icon(Icons.cloud_off,color:Color(0xFF167D62)),title:Text('Offline by design'),subtitle:Text('Your records stay on this device. No server or sign-in is required.')))]));}
 Widget _item(BuildContext c,IconData i,String t,String sub,VoidCallback f)=>Card(child:ListTile(onTap:f,leading:CircleAvatar(child:Icon(i)),title:Text(t),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right)));
}
