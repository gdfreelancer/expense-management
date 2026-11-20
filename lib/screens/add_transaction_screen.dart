import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../core/utils/formatters.dart';
import '../data/repositories/expense_repository.dart';
import '../models/expense_transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  AddTransactionScreen({
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
        SnackBar(
          content: Text(context.tr('Enter a title, valid amount, category and account.')),
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
        title: Text(widget.item == null ? context.tr('New transaction') : context.tr('Edit transaction')),
      ),
      body: busy
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18),
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'expense', label: Text(context.tr('Expense'))),
                    ButtonSegment(value: 'income', label: Text(context.tr('Income'))),
                  ],
                  selected: {type},
                  onSelectionChanged: (values) => changeType(values.first),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('Amount'),
                    prefixText: '₹ ',
                  ),
                ),
                SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: context.tr('Description')),
                ),
                SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  decoration: InputDecoration(labelText: context.tr('Category')),
                  items: categories
                      .map((item) => DropdownMenuItem<int>(
                            value: item['id'] as int,
                            child: Text(item['name'] as String),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => categoryId = value),
                ),
                SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: accountId,
                  decoration: InputDecoration(labelText: context.tr('Account')),
                  items: accounts
                      .map((item) => DropdownMenuItem<int>(
                            value: item['id'] as int,
                            child: Text(item['name'] as String),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => accountId = value),
                ),
                SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('Date')),
                  subtitle: Text(Fmt.date(date)),
                  trailing: Icon(Icons.calendar_month),
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
                  decoration: InputDecoration(labelText: context.tr('Note (optional)')),
                ),
                SizedBox(height: 16),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('Save transaction')),
                ),
              ],
            ),
    );
  }
}
