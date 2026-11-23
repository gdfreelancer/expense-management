import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_data.dart';
import '../l10n/app_localizations.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({
    super.key,
    required this.initialCode,
    required this.onSelected,
    this.showBackButton = true,
  });
  final String initialCode;
  final Future<void> Function(String) onSelected;
  final bool showBackButton;

  @override
  State<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  late String _selectedCode;
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCode = supportedCurrencies.any((item) => item.code == widget.initialCode)
        ? widget.initialCode
        : 'USD';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final query = _query.trim().toLowerCase();
    final options = supportedCurrencies.where((item) =>
      query.isEmpty ||
      item.name.toLowerCase().contains(query) ||
      item.code.toLowerCase().contains(query) ||
      item.symbol.toLowerCase().contains(query)).toList();
    final selected = supportedCurrencies.firstWhere((item) => item.code == _selectedCode);

    return Scaffold(
      appBar: widget.showBackButton
          ? AppBar(title: Text(t('Select currency')))
          : AppBar(automaticallyImplyLeading: false, title: Text(t('Choose your currency'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('Choose the currency used to display your amounts.'), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 13),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: t('Search currencies or codes'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _query = '')),
              ),
            ),
            const SizedBox(height: 9),
            Row(children: [
              const Icon(Icons.public_rounded, size: 15, color: AppTheme.brand),
              const SizedBox(width: 6),
              Expanded(child: Text('${supportedCurrencies.length} ${t('currencies available')}', style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600))),
              Text('${selected.code} · ${selected.symbol}', style: const TextStyle(fontSize: 11, color: AppTheme.brandDark, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        Expanded(
          child: options.isEmpty
              ? Center(child: Text(t('No currencies found'), style: Theme.of(context).textTheme.bodyMedium))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) => _currencyTile(options[index]),
                ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  try {
                    await widget.onSelected(_selectedCode);
                    if (widget.showBackButton && mounted) Navigator.of(context).pop();
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t('Continue')),
              ),
            ),
            const SizedBox(height: 7),
            Text(t('Changing currency does not convert existing amounts using exchange rates.'), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 10, height: 1.35)),
          ]),
        ),
      ]),
    );
  }

  Widget _currencyTile(CurrencyOption currency) {
    final selected = _selectedCode == currency.code;
    return Material(
      color: selected ? AppTheme.softGreen : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedCode = currency.code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppTheme.brand : AppTheme.border, width: selected ? 1.4 : .8),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: selected ? Colors.white : AppTheme.canvas, borderRadius: BorderRadius.circular(12)),
              child: Text(currency.symbol, maxLines: 1, style: const TextStyle(color: AppTheme.brandDark, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(currency.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.2, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: AppTheme.ink)),
              const SizedBox(height: 4),
              Text(currency.code, style: const TextStyle(fontSize: 10, letterSpacing: .7, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            ])),
            const SizedBox(width: 8),
            Text(currency.symbol, style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            const SizedBox(width: 9),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.brand : Colors.transparent,
                border: Border.all(color: selected ? AppTheme.brand : AppTheme.muted.withValues(alpha: .45), width: 1.4),
              ),
              child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
            ),
          ]),
        ),
      ),
    );
  }
}
