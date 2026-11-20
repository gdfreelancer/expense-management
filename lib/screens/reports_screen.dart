import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/extensions/iterable_extensions.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../models/expense_transaction.dart';

class ReportsScreen extends StatefulWidget {
  ReportsScreen({super.key});
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
    return _Data(
      await repo.totals(start, DateTime(now.year, now.month + 1)),
      await repo.transactions(type: 'expense', from: start),
      await repo.categories(type: 'expense'),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Reports'))),
    body: FutureBuilder<_Data>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final income = (data.totals['income'] ?? 0) / 100;
        final expense = (data.totals['expense'] ?? 0) / 100;
        final total = data.items.fold<int>(0, (sum, item) => sum + item.amountMinor);
        final totals = <int, int>{};
        for (final item in data.items) {
          totals[item.categoryId] = (totals[item.categoryId] ?? 0) + item.amountMinor;
        }
        final rows = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        String name(int id) => data.categories.where((e) => e['id'] == id).map((e) => e['name'] as String).firstOrNull ?? context.tr('Other');

        return ListView(padding: EdgeInsets.fromLTRB(18, 12, 18, 20), children: [
          Text(Fmt.month(DateTime.now()), style: TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SummaryCard(label: context.tr('Income'), amount: income, color: AppTheme.income, icon: Icons.south_west_rounded)),
            SizedBox(width: 10),
            Expanded(child: _SummaryCard(label: context.tr('Expenses'), amount: expense, color: AppTheme.expense, icon: Icons.north_east_rounded)),
          ]),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.ink, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Text(context.tr('Net savings'), style: TextStyle(color: Colors.white70, fontSize: 12))),
              Text(Fmt.money(income - expense), style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ),
          SizedBox(height: 19),
          Text(context.tr('Spending by category'), style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 10),
          if (rows.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppTheme.border)),
              child: Text(context.tr('No expenses recorded this month yet.'), style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            )
          else
            Container(
              padding: EdgeInsets.fromLTRB(14, 5, 14, 10),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
              child: Column(children: [
                for (var i = 0; i < rows.length; i++) ...[
                  _CategoryRow(name: context.tr(name(rows[i].key)), amount: rows[i].value, ratio: total == 0 ? 0.0 : (rows[i].value / total).clamp(0.0, 1.0).toDouble(), index: i),
                  if (i != rows.length - 1) Divider(height: 1, indent: 2),
                ],
              ]),
            ),
        ]);
      },
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  _SummaryCard({required this.label, required this.amount, required this.color, required this.icon});
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 16)),
      SizedBox(height: 10),
      Text(label, style: TextStyle(color: AppTheme.muted, fontSize: 11)),
      SizedBox(height: 3),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Fmt.money(amount), style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
    ]),
  );
}

class _CategoryRow extends StatelessWidget {
  _CategoryRow({required this.name, required this.amount, required this.ratio, required this.index});
  final String name;
  final int amount;
  final double ratio;
  final int index;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 11),
    child: Column(children: [
      Row(children: [
        Expanded(child: Text(name, style: TextStyle(color: AppTheme.ink, fontSize: 12, fontWeight: FontWeight.w700))),
        Text(Fmt.money(amount / 100), style: TextStyle(color: AppTheme.ink, fontSize: 12, fontWeight: FontWeight.w800)),
        SizedBox(width: 8),
        SizedBox(width: 34, child: Text('${(ratio * 100).round()}%', textAlign: TextAlign.end, style: TextStyle(color: AppTheme.muted, fontSize: 10))),
      ]),
      SizedBox(height: 7),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: Duration(milliseconds: 450 + index * 55),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: value, minHeight: 7, backgroundColor: AppTheme.canvas, color: AppTheme.brand),
        ),
      ),
    ]),
  );
}

class _Data {
  _Data(this.totals, this.items, this.categories);
  final Map<String, int> totals;
  final List<ExpenseTransaction> items;
  final List<Map<String, Object?>> categories;
}