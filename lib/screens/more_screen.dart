import 'package:flutter/material.dart';

import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _item(
            context,
            Icons.account_balance_wallet,
            'Accounts',
            'Manage cash and bank accounts',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountsScreen(onChanged: onChanged),
              ),
            ),
          ),
          _item(
            context,
            Icons.category,
            'Categories',
            'Customise income and expense types',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoriesScreen(onChanged: onChanged),
              ),
            ),
          ),
          _item(
            context,
            Icons.settings,
            'Settings',
            'App preferences and privacy',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              leading: Icon(Icons.cloud_off, color: Color(0xFF167D62)),
              title: Text('Offline by design'),
              subtitle: Text(
                'Your records stay on this device. No server or sign-in is required.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
