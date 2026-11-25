import 'package:flutter/material.dart';
import '../core/utils/currency_data.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';

class GoalsScreen extends StatefulWidget {
  GoalsScreen({super.key});
  @override State<GoalsScreen> createState() => _GoalsScreenState();
}
class _GoalsScreenState extends State<GoalsScreen> {
  final repo = ExpenseRepository();
  late Future<List<Map<String, Object?>>> future;
  @override void initState() { super.initState(); future = repo.goals(); }
  void reload() => setState(() => future = repo.goals());

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Savings goals'))),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: Icon(Icons.add_rounded), label: Text(context.tr('New goal'))),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return Center(child: CircularProgressIndicator());
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return Center(child: Text(context.tr('Create a savings target and watch your progress grow.')));
      return ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 90), children: rows.map((row) {
        final target = row['target_minor'] as int; final saved = row['saved_minor'] as int;
        final ratio = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0).toDouble();
        return Container(margin: EdgeInsets.only(bottom: 10), padding: EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.savings_rounded, color: AppTheme.brand)),
              SizedBox(width: 10), Expanded(child: Text(row['name'] as String, style: Theme.of(context).textTheme.titleMedium)),
              Text('${Fmt.number((ratio * 100).round())}%', style: TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800)),
              PopupMenuButton<String>(
                tooltip: context.tr('Goal options'),
                onSelected: (v) { if (v == 'edit') edit(row); if (v == 'delete') remove(row); },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: Icon(Icons.edit_outlined), title: Text(context.tr('Edit')))),
                  PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, color: Colors.red), title: Text(context.tr('Delete')))),
                ],
              ),
            ]),
            SizedBox(height: 13), TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: ratio), duration: Duration(milliseconds: 500), curve: Curves.easeOutCubic, builder: (context, value, _) => ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: AppTheme.canvas))),
            SizedBox(height: 8), Row(children: [Expanded(child: Text('${Fmt.money(saved / 100)} ${context.tr('saved')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), Text('${context.tr('of')}: ${Fmt.money(target / 100)}', style: Theme.of(context).textTheme.bodySmall)]),
            Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => contribute(row['id'] as int), icon: Icon(Icons.add_rounded, size: 17), label: Text(context.tr('Add savings')))),
          ]),
        );
      }).toList());
    }),
  );

  Future<void> add() async {
    final name = TextEditingController(); final amount = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(context.tr(item == null ? 'Create savings goal' : 'Edit savings goal')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: context.tr('Goal name'))),
        SizedBox(height: 12), TextField(controller: amount, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Target amount'), prefixText: '${CurrencySettings.selected.symbol} ')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr(item == null ? 'Create goal' : 'Save changes')))],
    ));
    final parsed = Fmt.parseAmount(amount.text);
    if (ok == true && name.text.trim().isNotEmpty && parsed != null && parsed > 0) { if (item == null) await repo.addGoal(name.text.trim(), (parsed * 100).round()); else await repo.updateGoal(item['id'] as int, name.text.trim(), (parsed * 100).round()); reload(); }
    name.dispose(); amount.dispose();
  }

  Future<void> remove(Map<String, Object?> row) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('Delete savings goal?')),
      content: Text(context.tr('This will delete the goal and its progress. It will not change any transactions.')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Delete')))],
    ));
    if (ok == true) { await repo.deleteGoal(row['id'] as int); if (mounted) reload(); }
  }

  Future<void> contribute(int id) async {
    final amount = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(context.tr('Add to savings')),
      content: TextField(controller: amount, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.tr('Contribution'), prefixText: '${CurrencySettings.selected.symbol} ')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Add savings')))],
    ));
    final parsed = Fmt.parseAmount(amount.text);
    if (ok == true && parsed != null && parsed > 0) { await repo.contributeGoal(id, (parsed * 100).round()); reload(); }
    amount.dispose();
  }
}