import 'package:flutter_test/flutter_test.dart';
import 'package:expense_management/core/utils/formatters.dart';

void main() {
  test('formats money using the app currency symbol', () {
    expect(Fmt.money(1250), contains('₹'));
  });

  test('formats calendar dates', () {
    expect(Fmt.date(DateTime(2026, 11, 18)), '18 Nov 2026');
  });
}
