import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';

class RecurringScreen extends StatefulWidget {
  RecurringScreen({super.key});
  @override State<RecurringScreen> createState() => _RecurringScreenState();
}
class _RecurringScreenState extends State<RecurringScreen> {
  final repo = ExpenseRepository();
  late Future<List<Map<String, Object?>>> future;
  @override void initState() { super.initState(); future = repo.recurring(); }
  void reload() => setState(() => future = repo.recurring());

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Recurring payments'))),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: Icon(Icons.add_rounded), label: Text(context.tr('Add recurring'))),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return Center(child: CircularProgressIndicator());
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return Center(child: Text(context.tr('No recurring payments yet. Add regular bills to keep track of them.')));
      return ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 90), children: rows.map((row) {
        final active = (row['is_active'] as int) == 1;
        return Container(margin: EdgeInsets.only(bottom: 9), padding: EdgeInsets.fromLTRB(13, 10, 8, 10),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.event_repeat_rounded, color: AppTheme.brand)),
            SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['title'] as String, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 3), Text('${row['frequency']} · ${row['category_name'] ?? context.tr('Category')}', style: Theme.of(context).textTheme.bodySmall),
              Text('${context.tr('Next')}: ${Fmt.date(DateTime.fromMillisecondsSinceEpoch(row['next_date_ms'] as int))}', style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: 3), Text(Fmt.money((row['amount_minor'] as int) / 100), style: TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800, fontSize: 12)),
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
    if (cats.isEmpty || accounts.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('Add an expense category and account first.')))); return; }
    int category = cats.first['id'] as int; int account = accounts.first['id'] as int; String frequency = 'monthly';
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
      title: Text(context.tr('New recurring payment')),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: context.tr('Payment name'))),
        SizedBox(height: 11), TextField(controller: amount, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Amount'), prefixText: '₹ ')),
        SizedBox(height: 11), DropdownButtonFormField<int>(value: category, decoration: InputDecoration(labelText: context.tr('Category')), items: cats.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['name'] as String))).toList(), onChanged: (v) { if (v != null) setDialogState(() => category = v); }),
        SizedBox(height: 11), DropdownButtonFormField<int>(value: account, decoration: InputDecoration(labelText: context.tr('Account')), items: accounts.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['name'] as String))).toList(), onChanged: (v) { if (v != null) setDialogState(() => account = v); }),
        SizedBox(height: 11), DropdownButtonFormField<String>(value: frequency, decoration: InputDecoration(labelText: context.tr('Frequency')), items: [DropdownMenuItem(value: 'weekly', child: Text(context.tr('Weekly'))), DropdownMenuItem(value: 'monthly', child: Text(context.tr('Monthly'))), DropdownMenuItem(value: 'yearly', child: Text(context.tr('Yearly')))], onChanged: (v) { if (v != null) setDialogState(() => frequency = v); }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Save')))],
    )));
    final parsed = double.tryParse(amount.text.trim());
    if (ok == true && title.text.trim().isNotEmpty && parsed != null && parsed > 0) { await repo.addRecurring(title.text.trim(), (parsed * 100).round(), 'expense', category, account, frequency, DateTime.now()); reload(); }
    title.dispose(); amount.dispose();
  }
}