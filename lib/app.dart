import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/currency_data.dart';
import 'core/utils/currency_scope.dart';
import 'l10n/app_localizations.dart';
import 'screens/startup_screen.dart';

class ExpenseApp extends StatefulWidget {
  const ExpenseApp({super.key});
  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  String languageCode = 'en_US';
  String currencyCode = 'USD';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Intl.defaultLocale = intlLocaleForLanguageCode(languageCode);
  }

  Future<void> _changeLanguage(String code) async {
    if (!supportedLanguageOptions.any((item) => item.code == code)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    if (mounted) {
      setState(() {
        languageCode = code;
        Intl.defaultLocale = intlLocaleForLanguageCode(code);
      });
    }
  }

  Future<void> _changeCurrency(String code) async {
    if (!supportedCurrencies.any((item) => item.code == code)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
    CurrencySettings.code = code;
    if (mounted) setState(() => currencyCode = code);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
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
    builder: (context, child) => LocaleScope(
      languageCode: languageCode,
      onLanguageChanged: _changeLanguage,
      child: CurrencyScope(
        currencyCode: currencyCode,
        onCurrencyChanged: _changeCurrency,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
    home: StartupScreen(onLanguageChanged: _changeLanguage, onCurrencyChanged: _changeCurrency),
  );
}
