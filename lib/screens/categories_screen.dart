import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/expense_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override State<CategoriesScreen> createState() => _CategoriesScreenState();
}
class _CategoriesScreenState extends State<CategoriesScreen> {
  final repo = ExpenseRepository();
  String type = 'expense';
  late Future<List<Map<String, Object?>>> future;
  @override void initState() { super.initState(); future = repo.categories(type: type); }
  void changeType(String value) => setState(() { type = value; future = repo.categories(type: value); });

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Categories')),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.add_rounded), label: const Text('Add category')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: SegmentedButton<String>(
        segments: const [ButtonSegment(value: 'expense', label: Text('Expenses')), ButtonSegment(value: 'income', label: Text('Income'))],
        selected: {type}, onSelectionChanged: (values) => changeType(values.first),
      )),
      Expanded(child: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('No categories found.'));
        return ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 90), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 7), itemBuilder: (context, index) {
          final row = rows[index]; final isDefault = (row['is_default'] as int) == 1;
          final accent = type == 'income' ? AppTheme.income : AppTheme.expense;
          return Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.sell_outlined, color: accent, size: 18)),
              const SizedBox(width: 11), Expanded(child: Text(row['name'] as String, style: Theme.of(context).textTheme.titleMedium)),
              if (isDefault) const Text('DEFAULT', style: TextStyle(fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w800, color: AppTheme.muted)) else const Icon(Icons.check_circle_outline_rounded, color: AppTheme.brand, size: 18),
            ]),
          );
        });
      })),
    ]),
  );

  Future<void> add() async {
    final name = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(type == 'income' ? 'New income category' : 'New expense category'),
      content: TextField(controller: name, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Category name', prefixIcon: Icon(Icons.sell_outlined))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save category'))],
    ));
    if (result == true && name.text.trim().isNotEmpty) {
      await repo.addCategory(name.text.trim(), type); widget.onChanged();
      setState(() => future = repo.categories(type: type));
    }
    name.dispose();
  }
}