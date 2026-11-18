import 'package:intl/intl.dart';
class Fmt{
 static String money(num n)=>'₹'+NumberFormat('#,##,##0.##','en_IN').format(n);
 static String date(DateTime d)=>DateFormat('d MMM yyyy').format(d);
 static String month(DateTime d)=>DateFormat('MMMM yyyy').format(d);
}
