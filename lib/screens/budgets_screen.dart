import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final repo = ExpenseRepository();
  late Future<_Data> future;
  String get month => '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<_Data> load() async => _Data(await repo.budgets(month), await repo.categories(type: 'expense'));
  void reload() => setState(() => future = load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Monthly budgets')),
    body: FutureBuilder<_Data>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final limit = data.rows.fold<int>(0, (sum, row) => sum + (row['amount_minor'] as int));
        final spent = data.rows.fold<int>(0, (sum, row) => sum + (row['spent_minor'] as int));
        final ratio = limit == 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF176F5B), Color(0xFF104C40)]),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Fmt.month(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                Text(Fmt.money(spent / 100), style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text('of ${Fmt.money(limit / 100)} planned', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 13),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(value: value, minHeight: 8, color: const Color(0xFF9DE2C4), backgroundColor: Colors.white24),
                  ),
                ),
                const SizedBox(height: 7),
                Row(children: [
                  const Expanded(child: Text('Monthly spending', style: TextStyle(color: Colors.white70, fontSize: 10))),
                  Text('${(ratio * 100).round()}% used', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
            const SizedBox(height: 17),
            Row(children: [
              Expanded(child: Text('Category limits', style: Theme.of(context).textTheme.titleLarge)),
              FilledButton.tonalIcon(onPressed: () => addBudget(data.cats), icon: const Icon(Icons.add, size: 17), label: const Text('Set budget')),
            ]),
            const SizedBox(height: 8),
            if (data.rows.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
                child: const Row(children: [
                  Icon(Icons.pie_chart_outline_rounded, color: AppTheme.muted),
                  SizedBox(width: 10),
                  Expanded(child: Text('No budgets set for this month. Set a limit to track your spending.', style: TextStyle(color: AppTheme.muted, fontSize: 12))),
                ]),
              )
            else
              ...data.rows.map((row) {
                final cap = row['amount_minor'] as int;
                final used = row['spent_minor'] as int;
                final over = used > cap;
                final progress = cap == 0 ? 0.0 : (used / cap).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(row['category_name'] as String, style: const TextStyle(color: AppTheme.ink, fontSize: 13, fontWeight: FontWeight.w700))),
                      Text(Fmt.money(used / 100), style: const TextStyle(color: AppTheme.ink, fontSize: 12, fontWeight: FontWeight.w800)),
                      Text(' / ${Fmt.money(cap / 100)}', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                    ]),
                    const SizedBox(height: 9),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(value: value, minHeight: 7, color: over ? AppTheme.expense : AppTheme.brand, backgroundColor: AppTheme.canvas),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(over ? 'Over budget' : 'Remaining: ${Fmt.money((cap - used).clamp(0, cap) / 100)}', style: TextStyle(color: over ? AppTheme.expense : AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                );
              }),
          ],
        );
      },
    ),
  );

  Future<void> addBudget(List<Map<String, Object?>> cats) async {
    if (cats.isEmpty) return;
    int selected = cats.first['id'] as int;
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Set monthly budget'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              value: selected,
              items: cats.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['name'] as String))).toList(),
              onChanged: (value) { if (value != null) setDialogState(() => selected = value); },
            ),
            const SizedBox(height: 10),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monthly limit', prefixText: '₹ ')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    final value = double.tryParse(amount.text);
    if (ok == true && value != null && value > 0) {
      await repo.saveBudget(selected, (value * 100).round(), month);
      widget.onChanged();
      reload();
    }
    amount.dispose();
  }
}

class _Data {
  _Data(this.rows, this.cats);
  final List<Map<String, Object?>> rows;
  final List<Map<String, Object?>> cats;
}