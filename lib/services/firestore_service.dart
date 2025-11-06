import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  // --- load user deta ---
  Future<Map<String, dynamic>?> getUserData() async {
    if (_userId == null) return null;
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(_userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // --- total amount calculation ---
  Future<double> getAccountBalance() async {
    if (_userId == null) return 0.0;

    double totalIncome = 0.0;
    double totalExpense = 0.0;

    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['isExpense'] == true) {
          totalExpense += (data['amount'] ?? 0).toDouble();
        } else {
          totalIncome += (data['amount'] ?? 0).toDouble();
        }
      }
      return totalIncome - totalExpense; // Balance = Income - Expense
    } catch (e) {
      print('Error getting account balance: $e');
      return 0.0;
    }
  }

  // --- Calculating monthly income and expenses ---
  Future<Map<String, double>> getMonthlyIncomeExpense() async {
    if (_userId == null) return {'income': 0.0, 'expense': 0.0};

    double monthlyIncome = 0.0;
    double monthlyExpense = 0.0;

    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(
      now.year,
      now.month + 1,
      0,
    ).add(const Duration(days: 1));

    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThan: endOfMonth)
          .get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['isExpense'] == true) {
          monthlyExpense += (data['amount'] ?? 0).toDouble();
        } else {
          monthlyIncome += (data['amount'] ?? 0).toDouble();
        }
      }
      return {'income': monthlyIncome, 'expense': monthlyExpense};
    } catch (e) {
      print('Error getting monthly data: $e');
      return {'income': 0.0, 'expense': 0.0};
    }
  }


  Future<List<TransactionModel>> getRecentTransactions() async {
    if (_userId == null) return [];
    List<TransactionModel> transactions = [];
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(6) 
          .get();

      for (var doc in snapshot.docs) {
        transactions.add(TransactionModel.fromFirestore(doc));
      }
      return transactions;
    } catch (e) {
      print('Error getting recent transactions: $e');
      return [];
    }
  }

  // --- add new transection ---
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .add(transaction.toMap());
    } catch (e) {
      print('Error adding transaction: $e');
      throw e; 
    }
  }
}
