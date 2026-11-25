import 'package:flutter/material.dart';
import '../widgets/app_bottom_sheet.dart';
import '../core/utils/currency_data.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final repo = ExpenseRepository();
  late Future<List<Map<String, Object?>>> future;
  static const accountTypes = ['cash','bank','savings','current','credit','debit','wallet','mobile_wallet','prepaid','investment','loan','gift_card','business','other'];
  @override void initState() { super.initState(); future = repo.accounts(); }
  void reload() => setState(() => future = repo.accounts());

  IconData iconFor(String type) => switch (type) {
    'bank' || 'savings' || 'current' => Icons.account_balance_rounded,
    'credit' || 'debit' || 'prepaid' => Icons.credit_card_rounded,
    'wallet' || 'mobile_wallet' || 'gift_card' => Icons.wallet_rounded,
    'investment' => Icons.trending_up_rounded,
    'loan' => Icons.request_quote_rounded,
    'business' => Icons.storefront_rounded,
    'other' => Icons.more_horiz_rounded,
    _ => Icons.payments_rounded,
  };

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Accounts'))),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => edit(), icon: const Icon(Icons.add_rounded), label: Text(context.tr('Add account'))),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text(context.tr('Unable to load accounts.')));
      final rows = snapshot.data ?? [];
      return ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 96), children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(15)), child: Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.brand, size: 22), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('Track every place you keep money'), style: const TextStyle(color: AppTheme.brandDark, fontWeight: FontWeight.w800, fontSize: 13)),
            Text(context.tr('Cash, bank accounts, cards, wallets and more.'), style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          ])),
          Text('${rows.length}', style: const TextStyle(color: AppTheme.brand, fontSize: 20, fontWeight: FontWeight.w900)),
        ])),
        const SizedBox(height: 16),
        Text(context.tr('YOUR ACCOUNTS'), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        if (rows.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(context.tr('Add an account to organise your money.')))),
        ...rows.map((row) => FutureBuilder<int>(
          future: repo.balance(row['id'] as int, row['opening_minor'] as int),
          builder: (context, balance) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: Icon(iconFor(row['type'] as String), color: AppTheme.brand)),
              const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row['name'] as String, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3), Text(context.tr(row['type'] as String), style: Theme.of(context).textTheme.bodySmall),
              ])),
              Text(balance.hasData ? Fmt.money(balance.data! / 100) : '…', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              PopupMenuButton<String>(tooltip: context.tr('Account options'), onSelected: (v) { if (v == 'edit') edit(row); if (v == 'delete') remove(row); }, itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: const Icon(Icons.edit_outlined), title: Text(context.tr('Edit')))),
                PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: const Icon(Icons.delete_outline, color: Colors.red), title: Text(context.tr('Delete')))),
              ]),
            ])),
        )),
      ]);
    }),
  );

  Future<void> edit([Map<String, Object?>? item]) async {
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final amount = TextEditingController(text: item == null ? '0' : ((item['opening_minor'] as int) / 100).toStringAsFixed(2));
    String type = item?['type'] as String? ?? 'cash';
    final result = await showAppBottomSheet<bool>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AppBottomSheetFrame(
        title: Text(context.tr(item == null ? 'New account' : 'Edit account')),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr('Account name'), prefixIcon: const Icon(Icons.wallet_outlined))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: type, isExpanded: true, decoration: InputDecoration(labelText: context.tr('Account type')),
            items: accountTypes.map((value) => DropdownMenuItem(value: value, child: Text(context.tr(value)))).toList(),
            onChanged: (value) { if (value != null) setDialogState(() => type = value); }),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: context.tr('Opening balance'), prefixText: '${CurrencySettings.selected.symbol} ')),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Save account')))],
      ),
    ));
    final parsed = Fmt.parseAmount(amount.text);
    if (result == true && name.text.trim().isNotEmpty && parsed != null) {
      try {
        final opening = (parsed * 100).round();
        if (item == null) { await repo.addAccount(name.text.trim(), type, opening); }
        else { await repo.updateAccount(item['id'] as int, name.text.trim(), type, opening); }
        widget.onChanged(); if (mounted) reload();
      } catch (e) { if (mounted) _error(e); }
    } else if (result == true && (name.text.trim().isEmpty || parsed == null)) {
      _error(StateError('Enter a valid account name and opening balance.'));
    }
    name.dispose(); amount.dispose();
  }

  Future<void> remove(Map<String, Object?> item) async {
    final ok = await showAppBottomSheet<bool>(context: context, builder: (ctx) => AppBottomSheetFrame(
      title: Text(context.tr('Delete account?')),
      content: Text(context.tr('This account can only be deleted when no transactions or recurring payments use it.')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Delete')))],
    ));
    if (ok != true) return;
    try { await repo.deleteAccount(item['id'] as int); widget.onChanged(); if (mounted) reload(); }
    catch (e) { if (mounted) _error(e); }
  }

  void _error(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
}
