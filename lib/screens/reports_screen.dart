import 'package:flutter/material.dart';

import '../core/extensions/iterable_extensions.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../models/expense_transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final repo = ExpenseRepository();
  late Future<_Data> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<_Data> load() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    return _Data(
      await repo.totals(start, end),
      await repo.transactions(type: 'expense', from: start),
      await repo.categories(type: 'expense'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & insights')),
      body: FutureBuilder<_Data>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final income = ((data.totals['income'] ?? 0) / 100).toDouble();
          final expense = ((data.totals['expense'] ?? 0) / 100).toDouble();
          final total = data.items.fold<int>(
            0,
            (sum, item) => sum + item.amountMinor,
          );
          final categoryTotals = <int, int>{};
          for (final item in data.items) {
            categoryTotals[item.categoryId] =
                (categoryTotals[item.categoryId] ?? 0) + item.amountMinor;
          }
          final rows = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          String categoryName(int id) => data.categories
              .where((item) => item['id'] == id)
              .map((item) => item['name'] as String)
              .firstOrNull ?? 'Other';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                Fmt.month(DateTime.now()),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 14),
              _metric('Income', income, Colors.green),
              _metric('Expenses', expense, Colors.deepOrange),
              _metric('Net savings', income - expense, Colors.blue),
              const SizedBox(height: 20),
              Text(
                'Spending by category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Text('No expenses this month.')
              else
                ...rows.map((entry) {
                  final ratio = total == 0
                      ? 0.0
                      : (entry.value / total).clamp(0.0, 1.0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(categoryName(entry.key))),
                            Text(
                              '${Fmt.money(entry.value / 100)}  ${(ratio * 100).round()}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        LinearProgressIndicator(value: ratio, minHeight: 8),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _metric(String label, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text(
              Fmt.money(value),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Data {
  _Data(this.totals, this.items, this.categories);
  final Map<String, int> totals;
  final List<ExpenseTransaction> items;
  final List<Map<String, Object?>> categories;
}
