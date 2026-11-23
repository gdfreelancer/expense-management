class DefaultCategories {
  static const Map<String,List<String>> expense = {
    'Food & Dining':['Restaurants','Cafes & Coffee','Fast Food','Food Delivery','Groceries','Snacks','Bakery'],
    'Transportation':['Fuel','Public Transport','Taxi & Ride Sharing','Parking','Vehicle Maintenance','Tolls','Vehicle Insurance'],
    'Shopping':['Clothing & Shoes','Electronics','Home & Furniture','Accessories','Gifts','Online Shopping'],
    'Bills & Utilities':['Electricity','Water','Gas','Internet','Mobile Recharge','Phone Bill','Streaming'],
    'Housing':['Rent','Mortgage','Home Repairs','Furniture','Appliances','Property Tax','Home Insurance'],
    'Health & Medical':['Doctor','Medicines','Hospital','Dental Care','Eye Care','Health Insurance','Fitness'],
    'Entertainment':['Movies','Events & Concerts','Games','Hobbies','Music & Apps','Books','Sports'],
    'Education':['Tuition Fees','Books & Supplies','Courses','School Fees','Exams','Training'],
    'Travel':['Flights','Hotels','Local Transport','Travel Food','Activities','Travel Insurance'],
    'Family & Personal':['Childcare','Kids','Pets','Personal Care','Salon & Grooming','Laundry','Donations'],
    'Financial':['Bank Fees','Credit Card Payment','Loan Repayment','Interest','Taxes','Investments','Savings Transfer'],
    'Work & Business':['Office Supplies','Software & Tools','Marketing','Work Travel','Professional Services'],
    'Other Expenses':['Miscellaneous','Emergency','Other'],
  };
  static const Map<String,List<String>> income = {
    'Employment':['Salary','Bonus','Commission','Overtime'],
    'Business':['Business Sales','Services','Consulting','Side Business','Online Business'],
    'Investments':['Dividends','Interest Earned','Stocks','Mutual Funds','Bonds','Rental Income','Capital Gains'],
    'Other Income':['Gift Received','Refund','Cashback','Rewards','Government Benefits','Pension','Insurance Payout','Sale of Items','Other'],
  };
  static List<Map<String,Object?>> rows() {
    final out=<Map<String,Object?>>[];
    for(final group in expense.entries){out.add({'name':group.key,'type':'expense','parent':null});for(final name in group.value){out.add({'name':name,'type':'expense','parent':group.key});}}
    for(final group in income.entries){out.add({'name':group.key,'type':'income','parent':null});for(final name in group.value){out.add({'name':name,'type':'income','parent':group.key});}}
    return out;
  }
}