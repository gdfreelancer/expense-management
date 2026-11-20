import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_shell.dart';

class ExpenseApp extends StatefulWidget {
  const ExpenseApp({super.key});
  @override State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  String languageCode = 'en';
  @override void didChangeDependencies() { super.didChangeDependencies(); Intl.defaultLocale = languageCode; }
  @override void initState() {
    super.initState();
    _loadLanguage();
  }
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { languageCode = prefs.getString('language_code') ?? 'en'; Intl.defaultLocale = languageCode; });
  }
  Future<void> _changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    if (mounted) setState(() { languageCode = code; Intl.defaultLocale = code; });
  }

  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Pennywise',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: Locale(languageCode),
    supportedLocales: const [Locale('en'), Locale('hi'), Locale('gu')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => LocaleScope(languageCode: languageCode, onLanguageChanged: _changeLanguage, child: child ?? const SizedBox.shrink()),
    home: FutureBuilder(
      future: AppDatabase.instance.database,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.hasError) return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('${context.tr('Database error')}: ${snapshot.error}'))));
        return const MainShell();
      },
    ),
  );
}
