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
  @override void didChangeDependencies() { super.didChangeDependencies(); Intl.defaultLocale = intlLocaleForLanguageCode(languageCode); }
  @override void initState() {
    super.initState();
    _loadLanguage();
  }
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved = prefs.getString('language_code') ?? 'en';
    final valid = supportedLanguageOptions.any((item) => item.code == saved);
    setState(() {
      languageCode = valid ? saved : 'en';
      Intl.defaultLocale = intlLocaleForLanguageCode(languageCode);
    });
  }
  Future<void> _changeLanguage(String code) async {
    if (!supportedLanguageOptions.any((item) => item.code == code)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    if (mounted) setState(() { languageCode = code; Intl.defaultLocale = intlLocaleForLanguageCode(code); });
  }

  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Pennywise',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: localeForLanguageCode(languageCode),
    supportedLocales: supportedLanguageOptions.map((item) => item.locale).toList(growable: false),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
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
