import 'package:intl/intl.dart';
import 'currency_data.dart';

class Fmt {
  static String number(num n) => NumberFormat.decimalPattern(Intl.defaultLocale).format(n);

  static String money(num n) {
    final currency = CurrencySettings.selected;
    final formatter = NumberFormat.currency(
      locale: Intl.defaultLocale,
      name: currency.code,
      symbol: currency.symbol,
      decimalDigits: 2,
    );
    return formatter.format(n);
  }

  static double? parseAmount(String input) {
    final value = input.trim().replaceAll(RegExp(r'\s+'), '');
    if (value.isEmpty) return null;
    try {
      return NumberFormat.decimalPattern(Intl.defaultLocale).parse(value).toDouble();
    } catch (_) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
  }

  static String date(DateTime d) => DateFormat.yMMMd().format(d);
  static String month(DateTime d) => DateFormat.yMMMM().format(d);
}
