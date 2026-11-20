import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'add_transaction_screen.dart';
import 'budgets_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'reports_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  int refresh = 0;
  void changed() => setState(() => refresh++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(key: ValueKey('home-$refresh'), onAdd: _add, onSeeAll: () => _selectTab(1)),
      TransactionsScreen(key: ValueKey('activity-$refresh'), onChanged: changed),
      BudgetsScreen(key: ValueKey('budgets-$refresh'), onChanged: changed),
      ReportsScreen(key: ValueKey('reports-$refresh')),
      MoreScreen(onChanged: changed),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 230),
        reverseDuration: const Duration(milliseconds: 170),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(begin: const Offset(0, 0.018), end: Offset.zero).animate(animation);
          return FadeTransition(opacity: animation, child: SlideTransition(position: slide, child: child));
        },
        child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
      ),
      bottomNavigationBar: _BottomBar(selected: tab, onSelected: _selectTab),
    );
  }

  void _selectTab(int value) {
    if (value != tab) setState(() => tab = value);
  }

  Future<void> _add() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(onSaved: changed)));
    if (mounted) changed();
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  static const items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Activity'),
    (Icons.pie_chart_rounded, Icons.pie_chart_outline_rounded, 'Budgets'),
    (Icons.insights_rounded, Icons.insights_outlined, 'Reports'),
    (Icons.grid_view_rounded, Icons.grid_view_outlined, 'More'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.border, width: 0.8))),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 62,
        child: Row(children: List.generate(items.length, (index) {
          final active = selected == index;
          final item = items[index];
          return Expanded(child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(color: active ? AppTheme.softGreen : Colors.transparent, borderRadius: BorderRadius.circular(13)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedScale(
                  scale: active ? 1.06 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(active ? item.$1 : item.$2, size: 21, color: active ? AppTheme.brand : AppTheme.muted),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(fontSize: 10, height: 1, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? AppTheme.brandDark : AppTheme.muted),
                  child: Text(item.$3),
                ),
              ]),
            ),
          ));
        })),
      ),
    ),
  );
}