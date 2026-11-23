import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_data.dart';
import '../core/utils/currency_scope.dart';
import '../l10n/app_localizations.dart';
import 'currency_selection_screen.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final localeScope = LocaleScope.of(context);
    final currencyScope = CurrencyScope.of(context);
    final selectedLanguage = supportedLanguageOptions.firstWhere(
      (item) => item.code == localeScope.languageCode,
      orElse: () => supportedLanguageOptions.first,
    );
    final selectedCurrency = supportedCurrencies.firstWhere(
      (item) => item.code == currencyScope.currencyCode,
      orElse: () => supportedCurrencies.firstWhere((item) => item.code == 'USD'),
    );

    return Scaffold(
      appBar: AppBar(title: Text(t('Settings'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), children: [
        _heading(context, t('PREFERENCES')),
        _preferenceTile(
          context,
          icon: Icons.translate_rounded,
          title: t('Language'),
          subtitle: selectedLanguage.name,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LanguageSelectionScreen(
              initialCode: localeScope.languageCode,
              onSelected: localeScope.onLanguageChanged,
            ),
          )),
        ),
        _preferenceTile(
          context,
          icon: Icons.currency_exchange_rounded,
          title: t('Currency'),
          subtitle: '${selectedCurrency.name} · ${selectedCurrency.code} · ${selectedCurrency.symbol}',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CurrencySelectionScreen(
              initialCode: currencyScope.currencyCode,
              onSelected: currencyScope.onCurrencyChanged,
            ),
          )),
        ),
        const SizedBox(height: 10),
        _heading(context, t('YOUR DATA')),
        _info(context, Icons.storage_rounded, t('Offline storage'), t('All transaction data is stored locally in SQLite.')),
        _info(context, Icons.lock_outline_rounded, t('Privacy'), t('No account, analytics service or cloud sync is configured.')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(13)),
          child: Text(
            t('Changing currency updates the currency display only. It does not convert existing amounts using exchange rates.'),
            style: const TextStyle(color: AppTheme.brandDark, fontSize: 11, height: 1.4),
          ),
        ),
      ]),
    );
  }

  Widget _heading(BuildContext context, String value) => Padding(
    padding: const EdgeInsets.fromLTRB(3, 13, 3, 8),
    child: Text(value, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
  );

  Widget _preferenceTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      dense: true,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.brand)),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
    ),
  );

  Widget _info(BuildContext context, IconData icon, String title, String subtitle) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppTheme.brand)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
      ])),
    ]),
  );
}
