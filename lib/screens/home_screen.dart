import 'package:flutter/material.dart';
import '../core/extensions/iterable_extensions.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onAdd, required this.onSeeAll});
  final VoidCallback onAdd;
  final VoidCallback onSeeAll;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      (await repo.transactions(from: start)).take(6).toList(),
      await repo.categories(),
      await repo.accounts(),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<_Data>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final income = (data.totals['income'] ?? 0) / 100;
        final expense = (data.totals['expense'] ?? 0) / 100;
        String category(int id) => data.categories.where((e) => e['id'] == id).map((e) => e['name'] as String).firstOrNull ?? 'Other';
        String account(int id) => data.accounts.where((e) => e['id'] == id).map((e) => e['name'] as String).firstOrNull ?? 'Account';

        return RefreshIndicator(
          onRefresh: () async => setState(() => future = load()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PENNYWISE', style: TextStyle(color: AppTheme.brand, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text('Good day', style: Theme.of(context).textTheme.headlineMedium),
                ])),
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.brand),
                ),
              ]),
              const SizedBox(height: 17),
              _BalanceCard(income: income, expense: expense),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _QuickAction(icon: Icons.add_rounded, label: 'Add expense', filled: true, onTap: widget.onAdd)),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(icon: Icons.south_west_rounded, label: 'Add income', onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(initialType: 'income', onSaved: () {})));
                  if (mounted) setState(() => future = load());
                })),
              ]),
              const SizedBox(height: 19),
              Row(children: [
                Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(onPressed: widget.onSeeAll, child: const Text('See all')),
              ]),
              const SizedBox(height: 3),
              if (data.items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppTheme.border)),
                  child: const Row(children: [
                    Icon(Icons.receipt_long_outlined, color: AppTheme.muted),
                    SizedBox(width: 11),
                    Expanded(child: Text('No transactions yet. Add your first one.', style: TextStyle(color: AppTheme.muted, fontSize: 12))),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppTheme.border)),
                  child: Column(children: [
                    for (var i = 0; i < data.items.length; i++) ...[
                      TransactionTile(item: data.items[i], category: category(data.items[i].categoryId), account: account(data.items[i].accountId)),
                      if (i != data.items.length - 1) const Divider(indent: 50, height: 1),
                    ],
                  ]),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.income, required this.expense});
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF176F5B), Color(0xFF104C40)]),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [BoxShadow(color: AppTheme.brand.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.account_balance_rounded, color: Colors.white70, size: 16),
          SizedBox(width: 7),
          Text('THIS MONTH', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
        ]),
        const SizedBox(height: 8),
        const Text('Net cash flow', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(animation), child: child),
          ),
          child: Text(Fmt.money(net), key: ValueKey(net), style: const TextStyle(color: Colors.white, fontSize: 29, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
        ),
        const SizedBox(height: 15),
        Container(height: 1, color: Colors.white24),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _BalanceMini(label: 'Income', value: income, icon: Icons.south_west_rounded)),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(child: Padding(padding: const EdgeInsets.only(left: 16), child: _BalanceMini(label: 'Expenses', value: expense, icon: Icons.north_east_rounded))),
        ]),
      ]),
    );
  }
}

class _BalanceMini extends StatelessWidget {
  const _BalanceMini({required this.label, required this.value, required this.icon});
  final String label;
  final double value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, color: Colors.white70, size: 13), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
    const SizedBox(height: 4),
    Text(Fmt.money(value), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
  ]);
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.filled = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) => Material(
    color: filled ? AppTheme.brand : Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: filled ? null : Border.all(color: AppTheme.border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 17, color: filled ? Colors.white : AppTheme.brand),
          const SizedBox(width: 6),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: filled ? Colors.white : AppTheme.brandDark))),
        ]),
      ),
    ),
  );
}

class _Data {
  _Data(this.totals, this.items, this.categories, this.accounts);
  final Map<String, int> totals;
  final List items;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> accounts;
}