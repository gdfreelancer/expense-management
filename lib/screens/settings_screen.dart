import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String currency = 'INR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: ListTile(
              title: const Text('Display currency'),
              subtitle: const Text('Default currency'),
              trailing: DropdownButton<String>(
                value: currency,
                items: const [
                  DropdownMenuItem(value: 'INR', child: Text('INR ₹')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR €')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => currency = value);
                },
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.cloud_off),
              title: Text('Offline storage'),
              subtitle: Text('All transaction data is stored locally in SQLite.'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Privacy'),
              subtitle: Text(
                'No account, analytics service or cloud sync is configured.',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Currency selection is a display preference placeholder in this first version. Amounts are stored as integer minor units.',
            ),
          ),
        ],
      ),
    );
  }
}
