import 'package:intl/intl.dart';

class Fmt {
  static String money(num n) {
    final formatter = NumberFormat.decimalPattern(Intl.defaultLocale)
      ..maximumFractionDigits = 2
      ..minimumFractionDigits = 0;
    return '₹${formatter.format(n)}';
  }

  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String month(DateTime d) => DateFormat('MMMM yyyy').format(d);
}
