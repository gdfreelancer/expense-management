import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
  void reload() => setState(() => future = repo.categories(type: type));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Categories'))),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => add(), icon: Icon(Icons.add_rounded), label: Text(context.tr('Add category'))),
    body: Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 10), child: SegmentedButton<String>(
        segments: [ButtonSegment(value: 'expense', label: Text(context.tr('Expenses'))), ButtonSegment(value: 'income', label: Text(context.tr('Income')))],
        selected: {type}, onSelectionChanged: (values) => changeType(values.first),
      )),
      Expanded(child: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return Center(child: CircularProgressIndicator());
        final rows = snapshot.data ?? [];
        final roots = rows.where((row) => row['parent_id'] == null).toList();
        return ListView(padding: EdgeInsets.fromLTRB(16, 0, 16, 92), children: [
          Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(14)), child: Row(children: [
            Icon(Icons.category_rounded, color: AppTheme.brand), SizedBox(width: 9),
            Expanded(child: Text(context.tr('Organise spending with categories and subcategories'), style: TextStyle(color: AppTheme.brandDark, fontSize: 12, fontWeight: FontWeight.w700))),
            Text('${rows.length}', style: TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w900, fontSize: 18)),
          ])),
          SizedBox(height: 13),
          if (roots.isEmpty) Center(child: Padding(padding: EdgeInsets.all(24), child: Text(context.tr('No categories found.')))),
          ...roots.map((row) => _categoryCard(row, rows, 0)),
        ]);
      })),
    ]),
  );

  Widget _categoryCard(Map<String,Object?> row, List<Map<String,Object?>> all, int depth) {
    final children = all.where((item) => item['parent_id'] == row['id']).toList();
    final accent = type == 'income' ? AppTheme.income : AppTheme.expense;
    final isDefault = (row['is_default'] as int) == 1;
    return Container(
      margin: EdgeInsets.only(bottom: 8, left: depth == 0 ? 0 : 13),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Padding(padding: EdgeInsets.fromLTRB(12, 9, 5, 9), child: Row(children: [
          Container(width: depth == 0 ? 36 : 29, height: depth == 0 ? 36 : 29, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(10)), child: Icon(depth == 0 ? Icons.sell_outlined : Icons.subdirectory_arrow_right_rounded, color: accent, size: 17)),
          SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(row['name'] as String), style: TextStyle(fontSize: depth == 0 ? 13 : 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            if (depth == 0) Text('${children.length} ${context.tr('subcategories')}', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
          ])),
          IconButton(tooltip: context.tr('Add subcategory'), visualDensity: VisualDensity.compact, onPressed: () => add(parent: row), icon: Icon(Icons.add_circle_outline_rounded, color: AppTheme.brand, size: 20)),
          if (isDefault) Padding(padding: EdgeInsets.only(right: 6), child: Text(context.tr('DEFAULT'), style: TextStyle(fontSize: 8, letterSpacing: .5, fontWeight: FontWeight.w800, color: AppTheme.muted))),
        ])),
        if (children.isNotEmpty) ...[
          Divider(height: 1, color: AppTheme.border),
          Padding(padding: EdgeInsets.fromLTRB(7, 7, 7, 2), child: Column(children: children.map((child) => _categoryCard(child, all, depth + 1)).toList())),
        ],
      ]),
    );
  }

  Future<void> add({Map<String, Object?>? parent}) async {
    final name = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(parent == null ? (type == 'income' ? context.tr('New income category') : context.tr('New expense category')) : context.tr('New subcategory')),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (parent != null) Padding(padding: EdgeInsets.only(bottom: 10), child: Text('${context.tr('Under')}: ${context.tr(parent['name'] as String)}', style: TextStyle(color: AppTheme.muted, fontSize: 12))),
        TextField(controller: name, autofocus: true, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr(parent == null ? 'Category name' : 'Subcategory name'), prefixIcon: Icon(Icons.sell_outlined))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Save category')))],
    ));
    if (result == true && name.text.trim().isNotEmpty) {
      await repo.addCategory(name.text.trim(), type, parentId: parent?['id'] as int?);
      widget.onChanged(); reload();
    }
    name.dispose();
  }
}