import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../core/extensions/iterable_extensions.dart';
import '../data/repositories/expense_repository.dart';
import '../models/expense_transaction.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  TransactionsScreen({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final repo = ExpenseRepository();
  String filter = 'all';
  String query = '';
  late Future<_Data> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<_Data> load() async => _Data(
        await repo.transactions(type: filter),
        await repo.categories(),
        await repo.accounts(),
      );

  void reload() {
    setState(() => future = load());
  }

  Future<void> search() async {
    final controller = TextEditingController(text: query);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Search transactions')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.tr('Search by description'),
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.tr('Search')),
          ),
        ],
      ),
    );
    if (value != null && mounted) setState(() => query = value);
    controller.dispose();
  }

  Future<void> add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(onSaved: widget.onChanged),
      ),
    );
    if (mounted) reload();
  }

  Future<void> edit(ExpenseTransaction item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          item: item,
          onSaved: widget.onChanged,
        ),
      ),
    );
    if (mounted) reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity'),
        actions: [
          IconButton(
            onPressed: search,
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: FutureBuilder<_Data>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final items = data.items
              .where((item) =>
                  item.title.toLowerCase().contains(query.toLowerCase()))
              .toList();

          String categoryName(int id) => data.categories
              .where((item) => item['id'] == id)
              .map((item) => item['name'] as String)
              .firstOrNull ?? context.tr('Other');

          String accountName(int id) => data.accounts
              .where((item) => item['id'] == id)
              .map((item) => item['name'] as String)
              .firstOrNull ?? context.tr('Account');

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'all', label: Text(context.tr('All'))),
                    ButtonSegment(value: 'expense', label: Text(context.tr('Expenses'))),
                    ButtonSegment(value: 'income', label: Text(context.tr('Income'))),
                  ],
                  selected: {filter},
                  onSelectionChanged: (values) {
                    setState(() {
                      filter = values.first;
                      future = load();
                    });
                  },
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(context.tr('No matching transactions')))
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              color: Colors.red.shade50,
                              child: Icon(Icons.delete, color: Colors.red),
                            ),
                            confirmDismiss: (_) async =>
                                await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(context.tr('Delete transaction?')),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: Text(context.tr('Cancel')),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: Text(context.tr('Delete')),
                                      ),
                                    ],
                                  ),
                                ) ?? false,
                            onDismissed: (_) async {
                              await repo.delete(item.id!);
                              widget.onChanged();
                              if (mounted) reload();
                            },
                            child: TransactionTile(
                              item: item,
                              category: categoryName(item.categoryId),
                              account: accountName(item.accountId),
                              onTap: () => edit(item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: Icon(Icons.add),
        label: Text(context.tr('Add')),
      ),
    );
  }
}

class _Data {
  _Data(this.items, this.categories, this.accounts);
  final List<ExpenseTransaction> items;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> accounts;
}
