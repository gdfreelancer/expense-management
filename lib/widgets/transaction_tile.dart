import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/expense_transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item, required this.category, required this.account, this.onTap});
  final ExpenseTransaction item;
  final String category;
  final String account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == 'income';
    final accent = isIncome ? AppTheme.income : AppTheme.expense;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          child: Row(children: [
            Container(
              width: 39, height: 39,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(12)),
              child: Icon(isIncome ? Icons.south_west_rounded : Icons.north_east_rounded, color: accent, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.ink, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('$category  ·  $account', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
            ])),
            const SizedBox(width: 8),
            Text('${isIncome ? '+' : '−'}${Fmt.money(item.amountMinor / 100)}',
              style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
          ]),
        ),
      ),
    );
  }
}