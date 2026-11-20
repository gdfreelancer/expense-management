import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override State<DebtsScreen> createState() => _DebtsScreenState();
}
class _DebtsScreenState extends State<DebtsScreen> {
  final repo = ExpenseRepository();
  late Future<List<Map<String, Object?>>> future;
  @override void initState() { super.initState(); future = repo.debts(); }
  void reload() => setState(() => future = repo.debts());

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Debt tracker')),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.add_rounded), label: const Text('Add debt')),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const Center(child: Text('Add money you lend or borrow to track repayments.'));
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: rows.map((row) {
        final lent = row['direction'] == 'lent'; final remaining = row['remaining_minor'] as int;
        final done = remaining <= 0; final accent = lent ? AppTheme.income : AppTheme.expense;
        return Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(lent ? Icons.call_made_rounded : Icons.call_received_rounded, color: accent)),
            const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['person'] as String, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3), Text(lent ? 'You lent' : 'You borrowed', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3), Text('${Fmt.money(remaining / 100)} remaining', style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
            if (done) const Icon(Icons.check_circle_rounded, color: AppTheme.income) else TextButton(onPressed: () => settle(row['id'] as int, remaining), child: const Text('Repay')),
          ]),
        );
      }).toList());
    }),
  );

  Future<void> add() async {
    final person = TextEditingController(); final amount = TextEditingController(); String direction = 'lent';
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
      title: const Text('Add debt record'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: person, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Person or organisation')),
        const SizedBox(height: 12), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
        const SizedBox(height: 12), DropdownButtonFormField<String>(value: direction, decoration: const InputDecoration(labelText: 'Direction'), items: const [DropdownMenuItem(value: 'lent', child: Text('I lent money')), DropdownMenuItem(value: 'borrowed', child: Text('I borrowed money'))], onChanged: (v) { if (v != null) setDialogState(() => direction = v); }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save record'))],
    )));
    final parsed = double.tryParse(amount.text.trim());
    if (ok == true && person.text.trim().isNotEmpty && parsed != null && parsed > 0) { await repo.addDebt(person.text.trim(), direction, (parsed * 100).round()); reload(); }
    person.dispose(); amount.dispose();
  }

  Future<void> settle(int id, int remaining) async {
    final amount = TextEditingController(text: (remaining / 100).toStringAsFixed(2));
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Record repayment'),
      content: TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Repayment amount', prefixText: '₹ ')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm repayment'))],
    ));
    final parsed = double.tryParse(amount.text.trim());
    if (ok == true && parsed != null && parsed > 0) { await repo.settleDebt(id, (parsed * 100).round()); reload(); }
    amount.dispose();
  }
}