import 'dart:io';
import 'package:artho_app/models/transaction_model.dart';
import 'package:artho_app/screens/notification_screen.dart';
import 'package:artho_app/screens/profile_screen.dart';
import 'package:artho_app/services/firestore_service.dart';
import 'package:artho_app/utils/auto_monthly_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RangeFilter { today, week, month, year }

class _DateRange {
  final DateTime from;
  final DateTime to;
  const _DateRange(this.from, this.to);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onViewAll});
  final VoidCallback? onViewAll;

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
  String _userName = 'User';

  RangeFilter _filter = RangeFilter.today;

  String? localImagePath;

  @override
  void initState() {
    super.initState();
    fetchDataAndUser();
    loadLocalImage();
    _setCurrentDate();

    if (DateTime.now().day == 1) {
      generateAutoMonthlyReport(FirestoreService());
    }
  }

  Future<void> loadLocalImage() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() => localImagePath = pref.getString("profileImage"));
  }

  void refreshUserProfile() {
    fetchDataAndUser();
    loadLocalImage();
    setState(() {});
  }

  void _setCurrentDate() {
    _currentDate = DateFormat('EEEE dd MMMM').format(DateTime.now());
  }

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
        return _DateRange(
          startOfToday.subtract(const Duration(days: 6)),
          startOfToday.add(const Duration(days: 1)),
        );
      case RangeFilter.month:
        return _DateRange(
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1),
        );
      case RangeFilter.year:
        return _DateRange(
          DateTime(now.year, 1, 1),
          DateTime(now.year + 1, 1, 1),
        );
    }
  }

  Future<void> fetchDataAndUser() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _firestoreService.getUserData();

      if (userData != null) {
        _userName = userData['name'] ?? "User";
      }

      final bal = await _firestoreService.getAccountBalance();
      final incExp = await _firestoreService.getMonthlyIncomeExpense();

      await _loadRecentForFilter();

      if (mounted) {
        setState(() {
          _accountBalance = bal;
          _monthlyIncome = incExp['income'] ?? 0.0;
          _monthlyExpense = incExp['expense'] ?? 0.0;
        });
      }
    } catch (e) {
      print("Error: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRecentForFilter() async {
    final w = _windowFor(_filter);
    final tx = await _firestoreService.getRecentTransactions(
      from: w.from,
      to: w.to,
      limit: 6,
    );
    if (mounted) setState(() => _recentTransactions = tx);
  }

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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) => refreshUserProfile()); // Refresh when back
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage: localImagePath != null
                    ? FileImage(File(localImagePath!))
                    : const AssetImage('assets/images/artho_logo.png')
                          as ImageProvider,
              ),
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
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                fetchDataAndUser();
                loadLocalImage();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(_accountBalance),
                    const SizedBox(height: 20),
                    _buildIncomeExpenseSummary(_monthlyIncome, _monthlyExpense),
                    const SizedBox(height: 20),
                    _buildTimeFilterTabs(),
                    const SizedBox(height: 20),
                    _buildRecentTransactions(_recentTransactions),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    Color color = balance < 0
        ? const Color.fromRGBO(231, 76, 60, 1)
        : balance > 0
        ? const Color.fromRGBO(46, 204, 113, 1)
        : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Balance',
            style: TextStyle(color: Colors.white70),
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
        Expanded(child: _summaryCard('Income', income, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _summaryCard('Expenses', expense, Colors.red)),
      ],
    );
  }

  Widget _summaryCard(String label, double value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFilterTab('Today', RangeFilter.today),
        _buildFilterTab('Week', RangeFilter.week),
        _buildFilterTab('Month', RangeFilter.month),
        _buildFilterTab('Year', RangeFilter.year),
      ],
    );
  }

  Widget _buildFilterTab(String text, RangeFilter filter) {
    bool active = _filter == filter;
    return InkWell(
      onTap: () => _onFilterTap(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.blue : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<TransactionModel> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: widget.onViewAll ?? () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No recent transactions"),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (_, i) => _buildTransactionItem(list[i]),
              ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    bool exp = tx.type == 'expense';
    Color color = exp ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.1),
          child: Icon(
            exp ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text(tx.title),
        subtitle: Text(DateFormat('d MMM yyyy').format(tx.date)),
        trailing: Text(
          "${exp ? "-" : "+"}${tx.amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ),
    );
  }
}
