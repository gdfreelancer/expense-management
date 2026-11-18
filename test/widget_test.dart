import 'package:flutter_test/flutter_test.dart';import 'package:expense_management/app.dart';
void main(){testWidgets('Expense manager starts',(tester)async{await tester.pumpWidget(const ExpenseApp());await tester.pumpAndSettle();expect(find.text('YOUR MONEY, IN CONTROL'),findsOneWidget);});}
