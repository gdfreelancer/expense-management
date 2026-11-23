import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_data.dart';
import '../data/local/app_database.dart';
import '../l10n/app_localizations.dart';
import 'language_selection_screen.dart';
import 'currency_selection_screen.dart';
import 'main_shell.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, required this.onLanguageChanged, required this.onCurrencyChanged});
  final Future<void> Function(String) onLanguageChanged;
  final Future<void> Function(String) onCurrencyChanged;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _ready = false;
  bool _showLanguageSelection = false;
  bool _showCurrencySelection = false;
  String _initialLanguage = 'en_US';
  String _initialCurrency = 'USD';
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250))..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _prepareApp();
  }

  Future<void> _prepareApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('language_code');
      final valid = supportedLanguageOptions.any((item) => item.code == saved);
      _initialLanguage = valid ? saved! : 'en_US';
      if (valid) await widget.onLanguageChanged(_initialLanguage);
      final savedCurrency = prefs.getString('currency_code');
      final validCurrency = supportedCurrencies.any((item) => item.code == savedCurrency);
      _initialCurrency = validCurrency ? savedCurrency! : 'USD';
      CurrencySettings.code = _initialCurrency;
      await widget.onCurrencyChanged(_initialCurrency);
      await AppDatabase.instance.database;
      await Future.delayed(const Duration(milliseconds: 1550));
      if (!mounted) return;
      final hasOpenedBefore = prefs.getBool('has_opened_before') ?? false;
      final firstLaunch = !hasOpenedBefore && saved == null;
      setState(() {
        _showLanguageSelection = firstLaunch;
        _showCurrencySelection = false;
        _ready = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error; _ready = true; });
    }
  }

  Future<void> _selectLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    await widget.onLanguageChanged(code);
    if (mounted) setState(() {
      _showLanguageSelection = false;
      _showCurrencySelection = true;
    });
  }

  Future<void> _selectCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
    await prefs.setBool('has_opened_before', true);
    CurrencySettings.code = code;
    await widget.onCurrencyChanged(code);
    if (mounted) setState(() => _showCurrencySelection = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && _error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.expense, size: 38),
              const SizedBox(height: 12),
              Text('${context.tr('Unable to start the app')}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 7),
              Text('$_error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton(onPressed: () { setState(() { _ready = false; _error = null; }); _prepareApp(); }, child: Text(context.tr('Retry'))),
            ]),
          ),
        ),
      );
    }

    if (_ready) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        child: _showLanguageSelection
            ? LanguageSelectionScreen(
                key: const ValueKey('first-language-selection'),
                initialCode: _initialLanguage,
                showBackButton: false,
                onSelected: _selectLanguage,
              )
            : _showCurrencySelection
                ? CurrencySelectionScreen(
                    key: const ValueKey('first-currency-selection'),
                    initialCode: _initialCurrency,
                    showBackButton: false,
                    onSelected: _selectCurrency,
                  )
                : const MainShell(key: ValueKey('main-shell')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: AppTheme.brand,
                  borderRadius: BorderRadius.circular(29),
                  boxShadow: [BoxShadow(color: AppTheme.brand.withValues(alpha: .20), blurRadius: 28, offset: const Offset(0, 12))],
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 45),
              ),
            ),
            const SizedBox(height: 22),
            Text('Pennywise', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.brandDark, letterSpacing: -1)),
            const SizedBox(height: 7),
            Text(context.tr('Your money, made clear.'), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4)),
          ]),
        ),
      ),
    );
  }
}
