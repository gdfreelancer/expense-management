import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/expense_repository.dart';
import '../l10n/app_localizations.dart';

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
    floatingActionButton: FloatingActionButton.extended(onPressed: () => add(), icon: const Icon(Icons.add_rounded), label: Text(context.tr('Add category'))),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 10), child: SegmentedButton<String>(
        segments: [ButtonSegment(value: 'expense', label: Text(context.tr('Expenses'))), ButtonSegment(value: 'income', label: Text(context.tr('Income')))],
        selected: {type}, onSelectionChanged: (v) => changeType(v.first))),
      Expanded(child: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text(context.tr('Unable to load categories.')));
        final rows = snapshot.data ?? [];
        final roots = rows.where((e) => e['parent_id'] == null).toList();
        return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 90), children: [
          Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(13)), child: Row(children: [
            const Icon(Icons.category_rounded, color: AppTheme.brand), const SizedBox(width: 9),
            Expanded(child: Text(type == 'expense' ? context.tr('Expenses use a main category and one subcategory.') : context.tr('Income uses main categories only.'), style: const TextStyle(color: AppTheme.brandDark, fontSize: 12, fontWeight: FontWeight.w700))),
            Text('${roots.length}', style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w900, fontSize: 18)),
          ])),
          const SizedBox(height: 12),
          if (roots.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(context.tr('No categories found.')))),
          ...roots.map((root) {
            final children = rows.where((e) => e['parent_id'] == root['id']).toList();
            return Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)), child: Column(children: [
              ListTile(
                leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.sell_outlined, color: AppTheme.brand, size: 18)),
                title: Text(context.tr(root['name'] as String), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: type == 'expense' ? Text('${children.length} ${context.tr('subcategories')}') : null,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (type == 'expense') IconButton(tooltip: context.tr('Add subcategory'), onPressed: () => add(parent: root), icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.brand)),
                  _menu(root),
                ]),
              ),
              if (children.isNotEmpty) const Divider(height: 1),
              ...children.map((child) => Padding(padding: const EdgeInsets.only(left: 18), child: ListTile(
                dense: true, leading: const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: AppTheme.muted),
                title: Text(context.tr(child['name'] as String), style: const TextStyle(fontSize: 13)),
                trailing: _menu(child),
              ))),
            ]));
          }),
        ]);
      })),
    ]),
  );

  Widget _menu(Map<String, Object?> row) => PopupMenuButton<String>(
    tooltip: context.tr('Category options'),
    onSelected: (value) { if (value == 'edit') edit(row); if (value == 'delete') remove(row); },
    itemBuilder: (_) => [
      PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: const Icon(Icons.edit_outlined), title: Text(context.tr('Edit')))),
      PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: const Icon(Icons.delete_outline, color: Colors.red), title: Text(context.tr('Delete')))),
    ],
  );

  Future<void> add({Map<String, Object?>? parent}) async {
    if (type == 'income' && parent != null) return;
    final name = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(parent == null ? (type == 'income' ? context.tr('New income category') : context.tr('New expense category')) : context.tr('New subcategory')),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (parent != null) Padding(padding: const EdgeInsets.only(bottom: 9), child: Text('${context.tr('Under')}: ${context.tr(parent['name'] as String)}', style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
        TextField(controller: name, autofocus: true, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr(parent == null ? 'Category name' : 'Subcategory name'))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Save category')))],
    ));
    if (ok == true && name.text.trim().isNotEmpty) {
      try { await repo.addCategory(name.text.trim(), type, parentId: parent?['id'] as int?); widget.onChanged(); if (mounted) reload(); }
      catch (e) { if (mounted) _error(e); }
    }
    name.dispose();
  }

  Future<void> edit(Map<String, Object?> row) async {
    final name = TextEditingController(text: row['name'] as String);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('Edit category')), content: TextField(controller: name, autofocus: true, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr('Category name'))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Save')))],
    ));
    if (ok == true && name.text.trim().isNotEmpty) {
      try { await repo.updateCategory(row['id'] as int, name.text.trim()); widget.onChanged(); if (mounted) reload(); }
      catch (e) { if (mounted) _error(e); }
    }
    name.dispose();
  }

  Future<void> remove(Map<String, Object?> row) async {
    final isSub = row['parent_id'] != null;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('Delete category?')),
      content: Text(context.tr(isSub ? 'This subcategory can only be deleted when no transaction uses it.' : 'This category can only be deleted after its subcategories and linked records are removed.')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Delete')))],
    ));
    if (ok != true) return;
    try { await repo.deleteCategory(row['id'] as int); widget.onChanged(); if (mounted) reload(); }
    catch (e) { if (mounted) _error(e); }
  }

  void _error(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
}
