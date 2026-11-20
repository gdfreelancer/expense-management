import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});
  @override State<RecurringScreen> createState() => _RecurringScreenState();
}
class _RecurringScreenState extends State<RecurringScreen> {
  final repo = ExpenseRepository();
  late Future<List<Map<String, Object?>>> future;
  @override void initState() { super.initState(); future = repo.recurring(); }
  void reload() => setState(() => future = repo.recurring());

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recurring payments')),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.add_rounded), label: const Text('Add recurring')),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const Center(child: Text('No recurring payments yet. Add regular bills to keep track of them.'));
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: rows.map((row) {
        final active = (row['is_active'] as int) == 1;
        return Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.event_repeat_rounded, color: AppTheme.brand)),
            const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['title'] as String, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3), Text('${row['frequency']} · ${row['category_name'] ?? 'Category'}', style: Theme.of(context).textTheme.bodySmall),
              Text('Next: ${Fmt.date(DateTime.fromMillisecondsSinceEpoch(row['next_date_ms'] as int))}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3), Text(Fmt.money((row['amount_minor'] as int) / 100), style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
            Switch.adaptive(value: active, onChanged: (value) async { await repo.toggleRecurring(row['id'] as int, value); reload(); }),
          ]),
        );
      }).toList());
    }),
  );

  Future<void> add() async {
    final title = TextEditingController(); final amount = TextEditingController();
    final cats = await repo.categories(type: 'expense'); final accounts = await repo.accounts();
    if (!mounted) return;
    if (cats.isEmpty || accounts.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add an expense category and account first.'))); return; }
    int category = cats.first['id'] as int; int account = accounts.first['id'] as int; String frequency = 'monthly';
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
      title: const Text('New recurring payment'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Payment name')),
        const SizedBox(height: 11), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
        const SizedBox(height: 11), DropdownButtonFormField<int>(value: category, decoration: const InputDecoration(labelText: 'Category'), items: cats.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['name'] as String))).toList(), onChanged: (v) { if (v != null) setDialogState(() => category = v); }),
        const SizedBox(height: 11), DropdownButtonFormField<int>(value: account, decoration: const InputDecoration(labelText: 'Account'), items: accounts.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['name'] as String))).toList(), onChanged: (v) { if (v != null) setDialogState(() => account = v); }),
        const SizedBox(height: 11), DropdownButtonFormField<String>(value: frequency, decoration: const InputDecoration(labelText: 'Frequency'), items: const [DropdownMenuItem(value: 'weekly', child: Text('Weekly')), DropdownMenuItem(value: 'monthly', child: Text('Monthly')), DropdownMenuItem(value: 'yearly', child: Text('Yearly'))], onChanged: (v) { if (v != null) setDialogState(() => frequency = v); }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save'))],
    )));
    final parsed = double.tryParse(amount.text.trim());
    if (ok == true && title.text.trim().isNotEmpty && parsed != null && parsed > 0) { await repo.addRecurring(title.text.trim(), (parsed * 100).round(), 'expense', category, account, frequency, DateTime.now()); reload(); }
    title.dispose(); amount.dispose();
  }
}