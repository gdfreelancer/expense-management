import 'package:flutter/material.dart';

import '../core/extensions/iterable_extensions.dart';
import '../data/repositories/expense_repository.dart';
import '../models/expense_transaction.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.onChanged});
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
        title: const Text('Search transactions'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by description',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Search'),
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
        title: const Text('Activity'),
        actions: [
          IconButton(
            onPressed: search,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: FutureBuilder<_Data>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final items = data.items
              .where((item) =>
                  item.title.toLowerCase().contains(query.toLowerCase()))
              .toList();

          String categoryName(int id) => data.categories
              .where((item) => item['id'] == id)
              .map((item) => item['name'] as String)
              .firstOrNull ?? 'Other';

          String accountName(int id) => data.accounts
              .where((item) => item['id'] == id)
              .map((item) => item['name'] as String)
              .firstOrNull ?? 'Account';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'expense', label: Text('Expenses')),
                    ButtonSegment(value: 'income', label: Text('Income')),
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
                    ? const Center(child: Text('No matching transactions'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red.shade50,
                              child: const Icon(Icons.delete, color: Colors.red),
                            ),
                            confirmDismiss: (_) async =>
                                await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete transaction?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const Text('Delete'),
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
        icon: const Icon(Icons.add),
        label: const Text('Add'),
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
