class ExpenseTransaction {
  final String id;
  late final String title;
  late final double amount;
  late final DateTime date;
  late final bool isExpense;
  late final String category;

  ExpenseTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.category,
  });

  // Convert to Map for SQLite insert
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isExpense': isExpense ? 1 : 0,
      'category': category,
    };
  }
}
