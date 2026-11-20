import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../models/expense_transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.item,
    required this.onSaved,
  });

  final String initialType;
  final ExpenseTransaction? item;
  final VoidCallback onSaved;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final repo = ExpenseRepository();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String type = 'expense';
  DateTime date = DateTime.now();
  int? categoryId;
  int? accountId;
  List<Map<String, Object?>> categories = [];
  List<Map<String, Object?>> accounts = [];
  bool busy = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    type = item?.type ?? widget.initialType;
    date = item?.date ?? DateTime.now();
    titleController.text = item?.title ?? '';
    amountController.text =
        item == null ? '' : (item.amountMinor / 100).toStringAsFixed(2);
    noteController.text = item?.note ?? '';
    load();
  }

  Future<void> load() async {
    final loadedCategories = await repo.categories(type: type);
    final loadedAccounts = await repo.accounts();
    if (!mounted) return;
    setState(() {
      categories = loadedCategories;
      accounts = loadedAccounts;
      categoryId = widget.item?.categoryId ??
          (categories.isEmpty ? null : categories.first['id'] as int);
      accountId = widget.item?.accountId ??
          (accounts.isEmpty ? null : accounts.first['id'] as int);
      busy = false;
    });
  }

  Future<void> changeType(String value) async {
    setState(() => busy = true);
    final loadedCategories = await repo.categories(type: value);
    if (!mounted) return;
    setState(() {
      type = value;
      categories = loadedCategories;
      categoryId =
          categories.isEmpty ? null : categories.first['id'] as int;
      busy = false;
    });
  }

  Future<void> save() async {
    final parsedAmount = double.tryParse(amountController.text.trim());
    if (titleController.text.trim().isEmpty ||
        parsedAmount == null ||
        parsedAmount <= 0 ||
        categoryId == null ||
        accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a title, valid amount, category and account.'),
        ),
      );
      return;
    }

    setState(() => saving = true);
    await repo.save(
      ExpenseTransaction(
        id: widget.item?.id,
        title: titleController.text.trim(),
        type: type,
        amountMinor: (parsedAmount * 100).round(),
        categoryId: categoryId!,
        accountId: accountId!,
        date: date,
        note: noteController.text.trim(),
      ),
    );
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'New transaction' : 'Edit transaction'),
      ),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense')),
                    ButtonSegment(value: 'income', label: Text('Income')),
                  ],
                  selected: {type},
                  onSelectionChanged: (values) => changeType(values.first),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((item) => DropdownMenuItem<int>(
                            value: item['id'] as int,
                            child: Text(item['name'] as String),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => categoryId = value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: accountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts
                      .map((item) => DropdownMenuItem<int>(
                            value: item['id'] as int,
                            child: Text(item['name'] as String),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => accountId = value),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(Fmt.date(date)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (value != null && mounted) {
                      setState(() => date = value);
                    }
                  },
                ),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: const Text('Save transaction'),
                ),
              ],
            ),
    );
  }
}
