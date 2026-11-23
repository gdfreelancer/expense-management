import 'package:flutter/widgets.dart';
import 'currency_data.dart';

class CurrencyScope extends InheritedWidget {
  const CurrencyScope({
    super.key,
    required this.currencyCode,
    required this.onCurrencyChanged,
    required super.child,
  });

  final String currencyCode;
  final Future<void> Function(String) onCurrencyChanged;

  static CurrencyScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CurrencyScope>()!;

  @override
  bool updateShouldNotify(CurrencyScope oldWidget) =>
      currencyCode != oldWidget.currencyCode;
}
