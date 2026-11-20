import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override State<GoalsScreen> createState() => _GoalsScreenState();
}
class _GoalsScreenState extends State<GoalsScreen> {
  final repo = ExpenseRepository();
  late Future<List<Map<String, Object?>>> future;
  @override void initState() { super.initState(); future = repo.goals(); }
  void reload() => setState(() => future = repo.goals());

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Savings goals')),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.add_rounded), label: const Text('New goal')),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const Center(child: Text('Create a savings target and watch your progress grow.'));
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: rows.map((row) {
        final target = row['target_minor'] as int; final saved = row['saved_minor'] as int;
        final ratio = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0).toDouble();
        return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.savings_rounded, color: AppTheme.brand)),
              const SizedBox(width: 10), Expanded(child: Text(row['name'] as String, style: Theme.of(context).textTheme.titleMedium)),
              Text('${(ratio * 100).round()}%', style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 13), TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: ratio), duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, builder: (context, value, _) => ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: AppTheme.canvas))),
            const SizedBox(height: 8), Row(children: [Expanded(child: Text('${Fmt.money(saved / 100)} saved', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), Text('of ${Fmt.money(target / 100)}', style: Theme.of(context).textTheme.bodySmall)]),
            Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => contribute(row['id'] as int), icon: const Icon(Icons.add_rounded, size: 17), label: const Text('Add savings'))),
          ]),
        );
      }).toList());
    }),
  );

  Future<void> add() async {
    final name = TextEditingController(); final amount = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Create savings goal'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Goal name')),
        const SizedBox(height: 12), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target amount', prefixText: '₹ ')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Create goal'))],
    ));
    final parsed = double.tryParse(amount.text.trim());
    if (ok == true && name.text.trim().isNotEmpty && parsed != null && parsed > 0) { await repo.addGoal(name.text.trim(), (parsed * 100).round()); reload(); }
    name.dispose(); amount.dispose();
  }

  Future<void> contribute(int id) async {
    final amount = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Add to savings'),
      content: TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Contribution', prefixText: '₹ ')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add savings'))],
    ));
    final parsed = double.tryParse(amount.text.trim());
    if (ok == true && parsed != null && parsed > 0) { await repo.contributeGoal(id, (parsed * 100).round()); reload(); }
    amount.dispose();
  }
}