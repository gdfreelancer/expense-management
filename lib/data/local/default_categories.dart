class DefaultCategories {
  static const Map<String, List<String>> expense = {
    'Food & Dining': ['Restaurants', 'Cafes & Coffee', 'Fast Food', 'Food Delivery', 'Groceries', 'Snacks', 'Bakery', 'Other'],
    'Transportation': ['Fuel', 'Public Transport', 'Taxi & Ride Sharing', 'Parking', 'Vehicle Maintenance', 'Tolls', 'Vehicle Insurance', 'Other'],
    'Shopping': ['Clothing & Shoes', 'Electronics', 'Home & Furniture', 'Accessories', 'Gifts', 'Online Shopping', 'Other'],
    'Bills & Utilities': ['Electricity', 'Water', 'Gas', 'Internet', 'Mobile Recharge', 'Phone Bill', 'Streaming', 'Other'],
    'Housing': ['Rent', 'Mortgage', 'Home Repairs', 'Furniture', 'Appliances', 'Property Tax', 'Home Insurance', 'Other'],
    'Health & Medical': ['Doctor', 'Medicines', 'Hospital', 'Dental Care', 'Eye Care', 'Health Insurance', 'Fitness', 'Other'],
    'Entertainment': ['Movies', 'Events & Concerts', 'Games', 'Hobbies', 'Music & Apps', 'Books', 'Sports', 'Other'],
    'Education': ['Tuition Fees', 'Books & Supplies', 'Courses', 'School Fees', 'Exams', 'Training', 'Other'],
    'Travel': ['Flights', 'Hotels', 'Local Transport', 'Travel Food', 'Activities', 'Travel Insurance', 'Other'],
    'Family & Personal': ['Childcare', 'Kids', 'Pets', 'Personal Care', 'Salon & Grooming', 'Laundry', 'Donations', 'Other'],
    'Financial': ['Bank Fees', 'Credit Card Payment', 'Loan Repayment', 'Interest', 'Taxes', 'Investments', 'Savings Transfer', 'Other'],
    'Work & Business': ['Office Supplies', 'Software & Tools', 'Marketing', 'Work Travel', 'Professional Services', 'Other'],
    'Other Expenses': ['Miscellaneous', 'Emergency', 'Other'],
  };

  // Income categories intentionally have one level only. Profit and Loss share this list.
  static const List<String> income = [
    'Employment', 'Business', 'Investments', 'Rental Income',
    'Interest Income', 'Gifts Received', 'Refunds', 'Other Income',
  ];

  static List<Map<String, Object?>> rows() {
    final out = <Map<String, Object?>>[];
    for (final group in expense.entries) {
      out.add({'name': group.key, 'type': 'expense', 'parent': null});
      for (final name in group.value) {
        out.add({'name': name, 'type': 'expense', 'parent': group.key});
      }
    }
    for (final name in income) {
      out.add({'name': name, 'type': 'income', 'parent': null});
    }
    return out;
  }
}
