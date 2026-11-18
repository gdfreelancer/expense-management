import 'package:flutter/material.dart';
class AppTheme{
 static const green=Color(0xFF167D62),ink=Color(0xFF17211F),canvas=Color(0xFFF5F7F5);
 static ThemeData get light=>ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:green),scaffoldBackgroundColor:canvas,appBarTheme:const AppBarTheme(backgroundColor:canvas,foregroundColor:ink,elevation:0),cardTheme:CardThemeData(color:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:const BorderSide(color:Color(0xFFE7ECE8)))),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xFFE7ECE8)))),elevatedButtonTheme:ElevatedButtonThemeData(style:ElevatedButton.styleFrom(backgroundColor:green,foregroundColor:Colors.white,minimumSize:const Size.fromHeight(50))));
}
