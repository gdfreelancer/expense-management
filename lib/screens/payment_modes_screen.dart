import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/expense_repository.dart';
import '../l10n/app_localizations.dart';

class PaymentModesScreen extends StatefulWidget {
  const PaymentModesScreen({super.key});
  @override State<PaymentModesScreen> createState() => _PaymentModesScreenState();
}
class _PaymentModesScreenState extends State<PaymentModesScreen> {
  final repo = ExpenseRepository();
  late Future<List<Map<String, Object?>>> future;
  @override void initState() { super.initState(); future = repo.paymentModes(); }
  void reload() => setState(() => future = repo.paymentModes());

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Payment Modes'))),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => add(), icon: const Icon(Icons.add_rounded), label: Text(context.tr('Add payment mode'))),
    body: FutureBuilder<List<Map<String, Object?>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text(context.tr('Unable to load payment modes.')));
      final rows = snapshot.data ?? [];
      final roots = rows.where((e) => e['parent_id'] == null).toList();
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
        Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(13)), child: Text(context.tr('Choose a main payment mode and organise its payment options underneath.'), style: const TextStyle(color: AppTheme.brandDark, fontSize: 12))),
        const SizedBox(height: 12),
        if (roots.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(context.tr('No payment modes found.')))),
        ...roots.map((root) {
          final children = rows.where((e) => e['parent_id'] == root['id']).toList();
          return Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)), child: Column(children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.brand),
              title: Text(root['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${children.length} ${context.tr('sub payment modes')}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(tooltip: context.tr('Add sub payment mode'), onPressed: () => add(parent: root), icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.brand)),
                _menu(root),
              ]),
            ),
            if (children.isNotEmpty) const Divider(height: 1),
            ...children.map((child) => Padding(padding: const EdgeInsets.fromLTRB(18, 0, 12, 0), child: ListTile(
              dense: true, leading: const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: AppTheme.muted),
              title: Text(child['name'] as String, style: const TextStyle(fontSize: 13)), trailing: _menu(child),
            ))),
          ]));
        }),
      ]);
    }),
  );

  Widget _menu(Map<String, Object?> row) => PopupMenuButton<String>(
    tooltip: context.tr('Payment mode options'),
    onSelected: (v) { if (v == 'edit') edit(row); if (v == 'delete') remove(row); },
    itemBuilder: (_) => [
      PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: const Icon(Icons.edit_outlined), title: Text(context.tr('Edit')))),
      PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: const Icon(Icons.delete_outline, color: Colors.red), title: Text(context.tr('Delete')))),
    ],
  );

  Future<void> add({Map<String, Object?>? parent}) async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(parent == null ? context.tr('New main payment mode') : context.tr('New sub payment mode')),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (parent != null) Padding(padding: const EdgeInsets.only(bottom: 9), child: Text('${context.tr('Under')}: ${parent['name']}', style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
        TextField(controller: name, autofocus: true, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr('Payment mode name'))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Save')))],
    ));
    if (ok == true && name.text.trim().isNotEmpty) {
      try { await repo.addPaymentMode(name.text.trim(), parentId: parent?['id'] as int?); if (mounted) reload(); }
      catch (e) { if (mounted) _error(e); }
    }
    name.dispose();
  }

  Future<void> edit(Map<String, Object?> row) async {
    final name = TextEditingController(text: row['name'] as String);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('Edit payment mode')),
      content: TextField(controller: name, autofocus: true, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: context.tr('Payment mode name'))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Save')))],
    ));
    if (ok == true && name.text.trim().isNotEmpty) {
      try { await repo.updatePaymentMode(row['id'] as int, name.text.trim()); if (mounted) reload(); }
      catch (e) { if (mounted) _error(e); }
    }
    name.dispose();
  }

  Future<void> remove(Map<String, Object?> row) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('Delete payment mode?')),
      content: Text(context.tr(row['parent_id'] == null ? 'This main payment mode and its unused sub payment modes will be deleted. Modes used by expenses cannot be deleted.' : 'A payment mode used by an expense cannot be deleted.')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Delete')))],
    ));
    if (ok != true) return;
    try { await repo.deletePaymentMode(row['id'] as int); if (mounted) reload(); }
    catch (e) { if (mounted) _error(e); }
  }

  void _error(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
}
