import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  String currency = 'INR';
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), children: [
      Text('PREFERENCES', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
      const SizedBox(height: 9),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)), child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.currency_rupee_rounded, color: AppTheme.brand)),
        const SizedBox(width: 11), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Display currency', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          SizedBox(height: 3), Text('Choose the currency shown in the app', style: TextStyle(color: AppTheme.muted, fontSize: 11)),
        ])),
        DropdownButton<String>(value: currency, underline: const SizedBox.shrink(), items: const [
          DropdownMenuItem(value: 'INR', child: Text('INR ₹')), DropdownMenuItem(value: 'USD', child: Text('USD')), DropdownMenuItem(value: 'EUR', child: Text('EUR €')),
        ], onChanged: (value) { if (value != null) setState(() => currency = value); }),
      ])),
      const SizedBox(height: 19),
      Text('YOUR DATA', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
      const SizedBox(height: 9),
      _info(Icons.storage_rounded, 'Offline storage', 'All transaction data is stored locally in SQLite.'),
      _info(Icons.lock_outline_rounded, 'Privacy', 'No account, analytics service or cloud sync is configured.'),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(13)), child: const Text('Currency selection is currently a display preference placeholder. Amounts remain stored as integer minor units.', style: TextStyle(color: AppTheme.brandDark, fontSize: 11, height: 1.4))),
    ]),
  );
  Widget _info(IconData icon, String title, String subtitle) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppTheme.brand)),
      const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
      ])),
    ]),
  );
}