import 'package:intl/intl.dart';

class Fmt {
  static String number(num n) => NumberFormat.decimalPattern(Intl.defaultLocale).format(n);

  static String money(num n) {
    final formatter = NumberFormat.decimalPattern(Intl.defaultLocale)
      ..maximumFractionDigits = 2
      ..minimumFractionDigits = 0;
    return '₹${formatter.format(n)}';
  }

  static double? parseAmount(String input) {
    final value = input.trim().replaceAll(RegExp(r'\\s+'), '');
    if (value.isEmpty) return null;
    try {
      return NumberFormat.decimalPattern(Intl.defaultLocale).parseStrict(value).toDouble();
    } catch (_) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
  }

  static String date(DateTime d) => DateFormat.yMMMd().format(d);
  static String month(DateTime d) => DateFormat.yMMMM().format(d);
}
