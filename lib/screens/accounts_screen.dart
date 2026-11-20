import 'package:flutter/material.dart';
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
  @override void initState() { super.initState(); future = repo.accounts(); }
  void reload() => setState(() => future = repo.accounts());

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Accounts')),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.add_rounded), label: const Text('Add account')),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const Center(child: Text('Add an account to organise your money.'));
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
        Text('YOUR ACCOUNTS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...rows.map((row) => FutureBuilder<int>(
          future: repo.balance(row['id'] as int, row['opening_minor'] as int),
          builder: (context, balance) {
            final type = row['type'] as String;
            final icon = type == 'bank' ? Icons.account_balance_rounded : type == 'credit' ? Icons.credit_card_rounded : type == 'wallet' ? Icons.wallet_rounded : Icons.payments_rounded;
            return Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
              child: Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.brand)),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(row['name'] as String, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(type[0].toUpperCase() + type.substring(1), style: Theme.of(context).textTheme.bodySmall),
                ])),
                Text(balance.hasData ? Fmt.money(balance.data! / 100) : '…', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ]));
          },
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
        title: const Text('New account'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Account name', prefixIcon: Icon(Icons.wallet_outlined))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Account type'),
            items: const [DropdownMenuItem(value: 'cash', child: Text('Cash')), DropdownMenuItem(value: 'bank', child: Text('Bank')), DropdownMenuItem(value: 'wallet', child: Text('Wallet')), DropdownMenuItem(value: 'credit', child: Text('Credit card'))],
            onChanged: (value) { if (value != null) setDialogState(() => type = value); }),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Opening balance', prefixText: '₹ ')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save account'))],
      ),
    ));
    final parsed = double.tryParse(amount.text.trim());
    if (result == true && name.text.trim().isNotEmpty && parsed != null) {
      await repo.addAccount(name.text.trim(), type, (parsed * 100).round());
      widget.onChanged(); reload();
    }
    name.dispose(); amount.dispose();
  }
}