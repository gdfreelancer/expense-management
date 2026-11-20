import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';

class DebtsScreen extends StatefulWidget {
  DebtsScreen({super.key});
  @override State<DebtsScreen> createState() => _DebtsScreenState();
}
class _DebtsScreenState extends State<DebtsScreen> {
  final repo = ExpenseRepository();
  late Future<List<Map<String, Object?>>> future;
  @override void initState() { super.initState(); future = repo.debts(); }
  void reload() => setState(() => future = repo.debts());

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Debt tracker'))),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: Icon(Icons.add_rounded), label: Text(context.tr('Add debt'))),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return Center(child: CircularProgressIndicator());
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return Center(child: Text(context.tr('Add money you lend or borrow to track repayments.')));
      return ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 90), children: rows.map((row) {
        final lent = row['direction'] == 'lent'; final remaining = row['remaining_minor'] as int;
        final done = remaining <= 0; final accent = lent ? AppTheme.income : AppTheme.expense;
        return Container(margin: EdgeInsets.only(bottom: 9), padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(lent ? Icons.call_made_rounded : Icons.call_received_rounded, color: accent)),
            SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['person'] as String, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 3), Text(lent ? context.tr('You lent') : context.tr('You borrowed'), style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: 3), Text('${Fmt.money(remaining / 100)} remaining', style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
            if (done) Icon(Icons.check_circle_rounded, color: AppTheme.income) else TextButton(onPressed: () => settle(row['id'] as int, remaining), child: Text(context.tr('Repay'))),
          ]),
        );
      }).toList());
    }),
  );

  Future<void> add() async {
    final person = TextEditingController(); final amount = TextEditingController(); String direction = 'lent';
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
      title: Text(context.tr('Add debt record')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: person, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr('Person or organisation'))),
        SizedBox(height: 12), TextField(controller: amount, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
        SizedBox(height: 12), DropdownButtonFormField<String>(value: direction, decoration: InputDecoration(labelText: context.tr('Direction')), items: [DropdownMenuItem(value: 'lent', child: Text(context.tr('I lent money'))), DropdownMenuItem(value: 'borrowed', child: Text(context.tr('I borrowed money')))], onChanged: (v) { if (v != null) setDialogState(() => direction = v); }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Save record')))],
    )));
    final parsed = double.tryParse(amount.text.trim());
    if (ok == true && person.text.trim().isNotEmpty && parsed != null && parsed > 0) { await repo.addDebt(person.text.trim(), direction, (parsed * 100).round()); reload(); }
    person.dispose(); amount.dispose();
  }

  Future<void> settle(int id, int remaining) async {
    final amount = TextEditingController(text: (remaining / 100).toStringAsFixed(2));
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(context.tr('Record repayment')),
      content: TextField(controller: amount, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Repayment amount'), prefixText: '₹ ')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Confirm repayment')))],
    ));
    final parsed = double.tryParse(amount.text.trim());
    if (ok == true && parsed != null && parsed > 0) { await repo.settleDebt(id, (parsed * 100).round()); reload(); }
    amount.dispose();
  }
}