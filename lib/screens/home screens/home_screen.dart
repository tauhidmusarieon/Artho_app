import 'package:artho_app/models/transaction_model.dart';
import 'package:artho_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// --- Moved out of the class: range filter enum ---
enum RangeFilter { today, week, month, year }

/// --- Replace Dart 3 record with a simple helper type for max compatibility ---
class _DateRange {
  final DateTime from;
  final DateTime to;
  const _DateRange(this.from, this.to);
}

class HomeScreen extends StatefulWidget {
  // Key added here to call from MainScreen
  const HomeScreen({super.key, this.onViewAll}); // ✅ added optional callback

  final VoidCallback?
  onViewAll; // ✅ this allows MainScreen to control navigation

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;

  double _accountBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  List<TransactionModel> _recentTransactions = [];
  String _currentDate = '';
  String _userName = 'User'; // Default name

  // --- range filter state (Today is auto-selected) ---
  // like the weekly monthly yearly recent transection
  RangeFilter _filter = RangeFilter.today;

  @override
  void initState() {
    super.initState();
    fetchDataAndUser(); // Loading all data
    _setCurrentDate();
  }

  void _setCurrentDate() {
    _currentDate = DateFormat('EEEE dd MMMM').format(DateTime.now());
  }

  // --- helper to get [from, to) window for Firestore ---
  _DateRange _windowFor(RangeFilter filter) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case RangeFilter.today:
        return _DateRange(
          startOfToday,
          startOfToday.add(const Duration(days: 1)),
        );
      case RangeFilter.week:
        final from = startOfToday.subtract(
          const Duration(days: 6),
        ); // today + previous 6 days
        final to = startOfToday.add(const Duration(days: 1));
        return _DateRange(from, to);
      case RangeFilter.month:
        final from = DateTime(now.year, now.month, 1);
        final to = DateTime(now.year, now.month + 1, 1);
        return _DateRange(from, to);
      case RangeFilter.year:
        final from = DateTime(now.year, 1, 1);
        final to = DateTime(now.year + 1, 1, 1);
        return _DateRange(from, to);
    }
  }

  // --- load recent transactions for current filter ---
  Future<void> _loadRecentForFilter() async {
    final w = _windowFor(_filter);
    final tx = await _firestoreService.getRecentTransactions(
      from: w.from,
      to: w.to,
      limit: 6,
    );
    if (mounted) {
      setState(() => _recentTransactions = tx);
    }
  }

  Future<void> fetchDataAndUser() async {
    setState(() => _isLoading = true);
    try {
      // Loading user name
      final userData = await _firestoreService.getUserData();
      if (userData != null && userData['username'] != null) {
        _userName = userData['username'];
      }

      // Loading all financial data together
      final balance = await _firestoreService.getAccountBalance();
      final incomeExpense = await _firestoreService.getMonthlyIncomeExpense();

      // --- load recent with current filter (Today by default) ---
      await _loadRecentForFilter();

      if (mounted) {
        setState(() {
          _accountBalance = balance;
          _monthlyIncome = incomeExpense['income'] ?? 0.0;
          _monthlyExpense = incomeExpense['expense'] ?? 0.0;
          // _recentTransactions already set by _loadRecentForFilter
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- when a chip is tapped, change filter and reload ---
  Future<void> _onFilterTap(RangeFilter f) async {
    if (_filter == f) return;
    setState(() => _filter = f);
    await _loadRecentForFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 249, 246, 1),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/artho_logo.png'),
              radius: 20,
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  _userName, // Dynamic username
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDataAndUser, // on Refresh
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(_accountBalance),
                    const SizedBox(height: 20),
                    _buildIncomeExpenseSummary(_monthlyIncome, _monthlyExpense),
                    const SizedBox(height: 20),
                    _buildTimeFilterTabs(), // like the weekly monthly yearly recent transection
                    const SizedBox(height: 20),
                    _buildRecentTransactions(_recentTransactions),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    // Choose color based on balance value
    Color cardColor;
    if (balance < 0) {
      cardColor = const Color.fromRGBO(231, 76, 60, 1); // Negative balance
    } else if (balance > 0) {
      cardColor = const Color.fromRGBO(46, 204, 113, 1); // Positive balance
    } else {
      cardColor = Colors.grey; // Zero balance (optional)
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            'BDT ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseSummary(double income, double expense) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Income',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    income.toStringAsFixed(0), // Dynamic Income
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(46, 204, 113, 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Expenses',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    expense.toStringAsFixed(0), // Dynamic Expance
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(231, 76, 60, 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilterTabs() {
    // like the weekly monthly yearly recent transection
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFilterTab(
          'Today',
          isActive: _filter == RangeFilter.today,
          onTap: () => _onFilterTap(RangeFilter.today),
        ),
        _buildFilterTab(
          'Week',
          isActive: _filter == RangeFilter.week,
          onTap: () => _onFilterTap(RangeFilter.week),
        ),
        _buildFilterTab(
          'Month',
          isActive: _filter == RangeFilter.month,
          onTap: () => _onFilterTap(RangeFilter.month),
        ),
        _buildFilterTab(
          'Year',
          isActive: _filter == RangeFilter.year,
          onTap: () => _onFilterTap(RangeFilter.year),
        ),
      ],
    );
  }

  Widget _buildFilterTab(
    String text, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color.fromRGBO(33, 150, 243, 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive
                ? const Color.fromRGBO(33, 150, 243, 1)
                : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed:
                  widget.onViewAll ??
                  () {
                    // TODO: hook to MainScreen if needed
                    print('Navigate to Transaction Page (View All)');
                  },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No recent transactions.'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final bool isExpense = transaction.type == 'expense'; // <-- FIX
    final icon = isExpense ? Icons.arrow_downward : Icons.arrow_upward;
    final color = isExpense
        ? const Color.fromRGBO(231, 76, 60, 1)
        : const Color.fromRGBO(46, 204, 113, 1);
    final amountText = isExpense
        ? '-${transaction.amount.toStringAsFixed(0)}'
        : '+${transaction.amount.toStringAsFixed(0)}';

    // show formatted date under title
    final dateText = DateFormat('d MMM yyyy').format(transaction.date);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(dateText),
        trailing: Text(
          amountText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
