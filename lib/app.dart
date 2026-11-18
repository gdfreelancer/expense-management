import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'screens/main_shell.dart';
class ExpenseApp extends StatelessWidget{
 const ExpenseApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(title:'Pennywise',debugShowCheckedModeBanner:false,theme:AppTheme.light,home:FutureBuilder(future:AppDatabase.instance.database,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Scaffold(body:Center(child:CircularProgressIndicator()));if(s.hasError)return Scaffold(body:Center(child:Text('Database error: '+s.error.toString())));return const MainShell();}));
}
