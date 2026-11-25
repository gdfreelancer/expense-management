import 'package:flutter/material.dart';
import '../widgets/app_bottom_sheet.dart';
import '../core/utils/currency_data.dart';
import '../l10n/app_localizations.dart';
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
  String categoryLabel(String name, Object? parent) => parent == null ? context.tr(name) : '${context.tr(parent as String)}  ›  ${context.tr(name)}';

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Recurring payments'))),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => edit(), icon: const Icon(Icons.add_rounded), label: Text(context.tr('Add recurring'))),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text(context.tr('Unable to load recurring payments.')));
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return Center(child: Text(context.tr('No recurring payments yet. Add regular bills to keep track of them.')));
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: rows.map((row) {
        final active = (row['is_active'] as int) == 1;
        return Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.fromLTRB(13, 10, 5, 10),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.event_repeat_rounded, color: AppTheme.brand)),
            const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['title'] as String, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3), Text('${context.tr(row['frequency'] as String)} · ${row['category_name'] == null ? context.tr('Category') : categoryLabel(row['category_name'] as String, row['parent_category_name'])}', style: Theme.of(context).textTheme.bodySmall),
              Text('${context.tr('Next')}: ${Fmt.date(DateTime.fromMillisecondsSinceEpoch(row['next_date_ms'] as int))}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3), Text(Fmt.money((row['amount_minor'] as int) / 100), style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
            Switch.adaptive(value: active, onChanged: (value) async { await repo.toggleRecurring(row['id'] as int, value); reload(); }),
            PopupMenuButton<String>(
              tooltip: context.tr('Recurring options'),
              onSelected: (v) { if (v == 'edit') edit(row); if (v == 'delete') remove(row); },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: const Icon(Icons.edit_outlined), title: Text(context.tr('Edit')))),
                PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: const Icon(Icons.delete_outline, color: Colors.red), title: Text(context.tr('Delete')))),
              ],
            ),
          ]),
        );
      }).toList());
    }),
  );

  Future<void> edit([Map<String, Object?>? item]) async {
    final title = TextEditingController(text: item?['title'] as String? ?? '');
    final amount = TextEditingController(text: item == null ? '' : ((item['amount_minor'] as int) / 100).toStringAsFixed(2));
    final cats = await repo.categories(type: 'expense');
    final accounts = await repo.accounts();
    if (!mounted) { title.dispose(); amount.dispose(); return; }
    if (cats.isEmpty || accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('Add an expense category and account first.'))));
      title.dispose(); amount.dispose(); return;
    }
    int category = item?['category_id'] as int? ?? cats.first['id'] as int;
    int account = item?['account_id'] as int? ?? accounts.first['id'] as int;
    String frequency = item?['frequency'] as String? ?? 'monthly';
    DateTime nextDate = DateTime.fromMillisecondsSinceEpoch(item?['next_date_ms'] as int? ?? DateTime.now().millisecondsSinceEpoch);
    final ok = await showAppBottomSheet<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AppBottomSheetFrame(
      title: Text(context.tr(item == null ? 'New recurring payment' : 'Edit recurring payment')),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: context.tr('Payment name'))),
        const SizedBox(height: 11), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Amount'), prefixText: '${CurrencySettings.selected.symbol} ')),
        const SizedBox(height: 11), DropdownButtonFormField<int>(value: category, isExpanded: true, decoration: InputDecoration(labelText: context.tr('Category')), items: cats.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(categoryLabel(e['name'] as String, e['parent_name']), overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) { if (v != null) setDialogState(() => category = v); }),
        const SizedBox(height: 11), DropdownButtonFormField<int>(value: account, isExpanded: true, decoration: InputDecoration(labelText: context.tr('Account')), items: accounts.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(context.tr(e['name'] as String)))).toList(), onChanged: (v) { if (v != null) setDialogState(() => account = v); }),
        const SizedBox(height: 11), DropdownButtonFormField<String>(value: frequency, decoration: InputDecoration(labelText: context.tr('Frequency')), items: [DropdownMenuItem(value: 'weekly', child: Text(context.tr('Weekly'))), DropdownMenuItem(value: 'monthly', child: Text(context.tr('Monthly'))), DropdownMenuItem(value: 'yearly', child: Text(context.tr('Yearly')))], onChanged: (v) { if (v != null) setDialogState(() => frequency = v); }),
        const SizedBox(height: 6), ListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr('Next payment date')), subtitle: Text(Fmt.activityDate(nextDate)), trailing: const Icon(Icons.calendar_month_rounded), onTap: () async { final picked = await showDatePicker(context: dialogContext, initialDate: nextDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (picked != null) setDialogState(() => nextDate = picked); }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Save')))],
    )));
    final parsed = Fmt.parseAmount(amount.text);
    if (ok == true && title.text.trim().isNotEmpty && parsed != null && parsed > 0) {
      try {
        if (item == null) await repo.addRecurring(title.text.trim(), (parsed * 100).round(), 'expense', category, account, frequency, nextDate);
        else await repo.updateRecurring(item['id'] as int, title.text.trim(), (parsed * 100).round(), 'expense', category, account, frequency, nextDate);
        if (mounted) reload();
      } catch (e) { if (mounted) _error(e); }
    } else if (ok == true) { _error(StateError('Enter a payment name and a valid amount.')); }
    title.dispose(); amount.dispose();
  }

  Future<void> remove(Map<String, Object?> row) async {
    final ok = await showAppBottomSheet<bool>(context: context, builder: (ctx) => AppBottomSheetFrame(
      title: Text(context.tr('Delete recurring payment?')),
      content: Text(context.tr('Only this recurring schedule will be deleted. Existing transactions will remain unchanged.')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Delete')))],
    ));
    if (ok == true) { await repo.deleteRecurring(row['id'] as int); if (mounted) reload(); }
  }

  void _error(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
}
