import 'package:flutter/material.dart';
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
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: Icon(Icons.add_rounded), label: Text(context.tr('Add account'))),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return Center(child: CircularProgressIndicator());
      final rows = snapshot.data ?? [];
      return ListView(padding: EdgeInsets.fromLTRB(16, 10, 16, 96), children: [
        Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(15)), child: Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: AppTheme.brand, size: 22), SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('Track every place you keep money'), style: TextStyle(color: AppTheme.brandDark, fontWeight: FontWeight.w800, fontSize: 13)),
            Text(context.tr('Cash, bank accounts, cards, wallets and more.'), style: TextStyle(color: AppTheme.muted, fontSize: 11)),
          ])),
          Text('${rows.length}', style: TextStyle(color: AppTheme.brand, fontSize: 20, fontWeight: FontWeight.w900)),
        ])),
        SizedBox(height: 16),
        Text(context.tr('YOUR ACCOUNTS'), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
        SizedBox(height: 9),
        if (rows.isEmpty) Center(child: Padding(padding: EdgeInsets.all(28), child: Text(context.tr('Add an account to organise your money.')))),
        ...rows.map((row) => FutureBuilder<int>(
          future: repo.balance(row['id'] as int, row['opening_minor'] as int),
          builder: (context, balance) => Container(margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(13),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: Icon(iconFor(row['type'] as String), color: AppTheme.brand)),
              SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row['name'] as String, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 3), Text(context.tr(row['type'] as String), style: Theme.of(context).textTheme.bodySmall),
              ])),
              Text(balance.hasData ? Fmt.money(balance.data! / 100) : '…', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ])),
        )),
      ]);
    }),
  );

  Future<void> add() async {
    final name = TextEditingController();
    final amount = TextEditingController(text: '0');
    String type = 'cash';
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(context.tr('New account')),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr('Account name'), prefixIcon: Icon(Icons.wallet_outlined))),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(value: type, isExpanded: true, decoration: InputDecoration(labelText: context.tr('Account type')),
            items: accountTypes.map((value) => DropdownMenuItem(value: value, child: Text(context.tr(value)))).toList(),
            onChanged: (value) { if (value != null) setDialogState(() => type = value); }),
          SizedBox(height: 12),
          TextField(controller: amount, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Opening balance'), prefixText: '${CurrencySettings.selected.symbol} ')),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Save account')))],
      ),
    ));
    final parsed = Fmt.parseAmount(amount.text);
    if (result == true && name.text.trim().isNotEmpty && parsed != null) {
      await repo.addAccount(name.text.trim(), type, (parsed * 100).round());
      widget.onChanged(); reload();
    }
    name.dispose(); amount.dispose();
  }
}