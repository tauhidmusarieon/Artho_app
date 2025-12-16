import 'package:artho_app/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      //print('Error getting user data: $e');
      return null;
    }
  }

  // --- total amount calculation ---
  // NOTE: This now returns the *current month* balance (Income - Expense).
  Future<double> getAccountBalance() async {
    if (_userId == null) return 0.0;

    double totalIncome = 0.0;
    double totalExpense = 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThan: startOfNextMonth)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] ?? 0).toDouble();
        final type = (data['type'] as String?)?.toLowerCase();
        final isExpense = type == 'expense' || (data['isExpense'] == true);

        if (isExpense) {
          totalExpense += amount;
        } else {
          totalIncome += amount;
        }
      }

      return totalIncome - totalExpense;
    } catch (e) {
      //print('Error getting account balance: $e');
      return 0.0;
    }
  }

  // --- Calculating monthly income and expenses ---
  Future<Map<String, double>> getMonthlyIncomeExpense() async {
    if (_userId == null) return {'income': 0.0, 'expense': 0.0};

    double monthlyIncome = 0.0;
    double monthlyExpense = 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(
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
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] ?? 0).toDouble();
        final type = (data['type'] as String?)?.toLowerCase();
        final isExpense = type == 'expense' || (data['isExpense'] == true);

        if (isExpense) {
          monthlyExpense += amount;
        } else {
          monthlyIncome += amount;
        }
      }

      return {'income': monthlyIncome, 'expense': monthlyExpense};
    } catch (e) {
      //print('Error getting monthly data: $e');
      return {'income': 0.0, 'expense': 0.0};
    }
  }

  // --- helpers: totals by type in a custom date range ---
  Future<double> totalByTypeInRange(
    String type,
    DateTime from,
    DateTime to,
  ) async {
    if (_userId == null) return 0.0;
    try {
      final q = await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('type', isEqualTo: type)
          .where('date', isGreaterThanOrEqualTo: from)
          .where('date', isLessThan: to)
          .get();

      return q.docs.fold<double>(
        0.0,
        (sum, d) =>
            sum +
            ((d.data())['amount'] as num).toDouble(),
      );
    } catch (e) {
      //print('Error calculating totalByTypeInRange: $e');
      return 0.0;
    }
  }

  // --- recent transactions (optional date window) ---
  Future<List<TransactionModel>> getRecentTransactions({
    DateTime? from,
    DateTime? to,
    int limit = 6,
  }) async {
    if (_userId == null) return [];
    try {
      Query q = _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .orderBy('date', descending: true);

      if (from != null) {
        q = q.where('date', isGreaterThanOrEqualTo: from);
      }
      if (to != null) {
        q = q.where('date', isLessThan: to);
      }

      final snapshot = await q.limit(limit).get();
      return snapshot.docs.map(_txFromDoc).toList();
    } catch (e) {
      //print('Error getting recent transactions: $e');
      return [];
    }
  }

  // --- stream for lists with filters (Home chips & Transaction tab) ---
  Stream<List<TransactionModel>> streamTransactions({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) {
    if (_userId == null) return const Stream.empty();

    Query q = _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .orderBy('date', descending: true);

    if (from != null) {
      q = q.where('date', isGreaterThanOrEqualTo: from);
    }
    if (to != null) {
      q = q.where('date', isLessThan: to);
    }
    if (limit != null) {
      q = q.limit(limit);
    }

    return q.snapshots().map((s) => s.docs.map(_txFromDoc).toList());
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
      //print('Error adding transaction: $e');
      rethrow;
    }
  }

  // --- update transection (edit previous items) ---
  Future<void> updateTransaction(TransactionModel transaction) async {
    if (_userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      //print('Error updating transaction: $e');
      rethrow;
    }
  }

  // --- delete transection ---
  Future<void> deleteTransaction(String id) async {
    if (_userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .doc(id)
          .delete();
    } catch (e) {
      //print('Error deleting transaction: $e');
      rethrow;
    }
  }

  // ====== PRIVATE: map Firestore doc -> TransactionModel (handles legacy fields) ======
  TransactionModel _txFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle both new ('type') and old ('isExpense') schemas
    final String type =
        (data['type'] as String?)?.toLowerCase() ??
        ((data['isExpense'] == true) ? 'expense' : 'income');

    // Timestamp or DateTime or null
    final rawDate = data['date'];
    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else {
      date = DateTime.now();
    }

    return TransactionModel(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      amount: (data['amount'] ?? 0).toDouble(),
      type: type,
      category: (data['category'] ?? 'General') as String,
      date: date,
    );
  }


  // ===== TODAY: category wise EXPENSE =====
  Future<Map<String, double>> getTodayExpenseByCategory() async {
    if (_userId == null) return {};

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 1));

    final snap = await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThan: to)
        .get();

    final Map<String, double> result = {};

    for (var d in snap.docs) {
      final data = d.data();
      final type =
          (data['type'] as String?) ??
          ((data['isExpense'] == true) ? 'expense' : 'income');

      if (type != 'expense') continue;

      final cat = data['category'] ?? 'Other';
      final amt = (data['amount'] ?? 0).toDouble();
      result[cat] = (result[cat] ?? 0) + amt;
    }

    return result;
  }


  // ===== RANGE: income vs expense =====
  Future<Map<String, double>> getIncomeExpenseInRange(
    DateTime from,
    DateTime to,
  ) async {
    if (_userId == null) return {'income': 0, 'expense': 0};

    double income = 0;
    double expense = 0;

    final snap = await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThan: to)
        .get();

    for (var d in snap.docs) {
      final data = d.data();
      final amt = (data['amount'] ?? 0).toDouble();

      final type =
          (data['type'] as String?) ??
          ((data['isExpense'] == true) ? 'expense' : 'income');

      if (type == 'income') {
        income += amt;
      } else {
        expense += amt;
      }
    }

    return {'income': income, 'expense': expense};
  }

  Future<List<Map<String, dynamic>>> getTransactionsInRange(
    DateTime from,
    DateTime to,
  ) async {
    if (_userId == null) return [];

    final snap = await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThan: to)
        .get();

    return snap.docs.map((d) => {'id': d.id, 'data': d.data()}).toList();
  }



}
