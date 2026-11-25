import 'package:flutter/material.dart';
import '../widgets/app_bottom_sheet.dart';
import '../core/utils/currency_data.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import 'credit_debit_form_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key, required this.onChanged});
  final VoidCallback onChanged;
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
              SizedBox(height: 3), Text('${Fmt.money(remaining / 100)} ${context.tr('remaining')}', style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
            if (done) Icon(Icons.check_circle_rounded, color: AppTheme.income) else TextButton(onPressed: () => settle(row['id'] as int, remaining), child: Text(context.tr('Repay'))),
            PopupMenuButton<String>(
              tooltip: context.tr('Debt options'),
              onSelected: (v) { if (v == 'edit') edit(row); if (v == 'delete') remove(row); },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: Icon(Icons.edit_outlined), title: Text(context.tr('Edit')))),
                PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, color: Colors.red), title: Text(context.tr('Delete')))),
              ],
            ),
          ]),
        );
      }).toList());
    }),
  );

  Future<void> add() async {
    await showAppBottomSheet<void>(
      context: context,
      builder: (_) => CreditDebitFormScreen(
        onSaved: widget.onChanged,
        asBottomSheet: true,
      ),
    );
    if (mounted) reload();
  }

  Future<void> edit(Map<String, Object?> row) async {
    await showAppBottomSheet<void>(
      context: context,
      builder: (_) => CreditDebitFormScreen(
        item: row,
        onSaved: widget.onChanged,
        asBottomSheet: true,
      ),
    );
    if (mounted) reload();
  }

  Future<void> remove(Map<String, Object?> row) async {
    final ok = await showAppBottomSheet<bool>(context: context, builder: (ctx) => AppBottomSheetFrame(
      title: Text(context.tr('Delete debt record?')),
      content: Text(context.tr('Deleting this record also deletes its repayment history. This cannot be undone.')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Delete')))],
    ));
    if (ok == true) { await repo.deleteDebt(row['id'] as int); widget.onChanged(); if (mounted) reload(); }
  }

  Future<void> settle(int id, int remaining) async {
    final amount = TextEditingController(text: (remaining / 100).toStringAsFixed(2));
    final ok = await showAppBottomSheet<bool>(context: context, builder: (dialogContext) => AppBottomSheetFrame(
      title: Text(context.tr('Record repayment')),
      content: TextField(controller: amount, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Repayment amount'), prefixText: '${CurrencySettings.selected.symbol} ')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Confirm repayment')))],
    ));
    final parsed = Fmt.parseAmount(amount.text);
    if (ok == true && parsed != null && parsed > 0) { try { await repo.settleDebt(id, (parsed * 100).round()); widget.onChanged(); reload(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', '')))); } }
    amount.dispose();
  }
}