class ExpenseTransaction {
  final int? id;
  final String title;
  final String type; // expense, profit, loss
  final String note;
  final int amountMinor;
  final int categoryId;
  final int? subcategoryId;
  final int? paymentModeId;
  final int? subPaymentModeId;
  final int accountId;
  final DateTime date;

  const ExpenseTransaction({
    this.id,
    required this.title,
    required this.type,
    required this.amountMinor,
    required this.categoryId,
    this.subcategoryId,
    this.paymentModeId,
    this.subPaymentModeId,
    required this.accountId,
    required this.date,
    this.note = '',
  });

  factory ExpenseTransaction.fromMap(Map<String, Object?> map) {
    return ExpenseTransaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      type: map['type'] as String,
      amountMinor: map['amount_minor'] as int,
      categoryId: map['category_id'] as int,
      subcategoryId: map['subcategory_id'] as int?,
      paymentModeId: map['payment_mode_id'] as int?,
      subPaymentModeId: map['sub_payment_mode_id'] as int?,
      accountId: map['account_id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date_ms'] as int),
      note: (map['note'] as String?) ?? '',
    );
  }

  Map<String, Object?> toMap() => {
    'title': title,
    'type': type,
    'amount_minor': amountMinor,
    'category_id': categoryId,
    'subcategory_id': subcategoryId,
    'payment_mode_id': paymentModeId,
    'sub_payment_mode_id': subPaymentModeId,
    'account_id': accountId,
    'date_ms': date.millisecondsSinceEpoch,
    'note': note,
  };
}
