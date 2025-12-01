
class TransactionModel {
  final String id; // Firestore document ID
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category; // e.g. Food, Salary, Mess
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  // For saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
    };
  }
}
