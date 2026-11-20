import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'debts_screen.dart';
import 'goals_screen.dart';
import 'recurring_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), children: [
      _heading(context, 'MANAGE'),
      _item(context, Icons.account_balance_wallet_rounded, 'Accounts', 'Cash, bank and wallet balances', () => _open(context, AccountsScreen(onChanged: onChanged))),
      _item(context, Icons.category_rounded, 'Categories', 'Organise income and expenses', () => _open(context, CategoriesScreen(onChanged: onChanged))),
      _heading(context, 'PLAN AHEAD'),
      _item(context, Icons.event_repeat_rounded, 'Recurring payments', 'Keep track of regular bills', () => _open(context, const RecurringScreen())),
      _item(context, Icons.savings_rounded, 'Savings goals', 'Track progress towards your goals', () => _open(context, const GoalsScreen())),
      _item(context, Icons.handshake_rounded, 'Debt tracker', 'Track money lent and borrowed', () => _open(context, const DebtsScreen())),
      _heading(context, 'PREFERENCES'),
      _item(context, Icons.tune_rounded, 'Settings', 'App preferences and privacy', () => _open(context, const SettingsScreen())),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(15)), child: const Row(children: [
        Icon(Icons.shield_moon_rounded, color: AppTheme.brand), SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Private by design', style: TextStyle(color: AppTheme.brandDark, fontWeight: FontWeight.w800, fontSize: 13)),
          SizedBox(height: 3), Text('Your records stay on this device. No sign-in or server required.', style: TextStyle(color: AppTheme.muted, fontSize: 11, height: 1.35)),
        ])),
      ])),
    ]),
  );
  Widget _heading(BuildContext context, String value) => Padding(padding: const EdgeInsets.fromLTRB(3, 13, 3, 7), child: Text(value, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted, letterSpacing: 1.1, fontWeight: FontWeight.w800)));
  Widget _item(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)),
    child: ListTile(dense: true, onTap: onTap,
      leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppTheme.brand, size: 19)),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium), subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.muted)),
  );
  void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}