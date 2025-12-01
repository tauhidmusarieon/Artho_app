import 'package:artho_app/screens/add_transaction_screen.dart';
import 'package:artho_app/screens/home screens/home_screen.dart';
import 'package:artho_app/screens/profile_screen.dart';
import 'package:artho_app/screens/statistics_screen.dart';
import 'package:artho_app/screens/transaction_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // ✅ pass callback to go to transactions tab
      HomeScreen(
        key: _homeKey,
        onViewAll: _goToTransactions, // ✅ this will now work
      ),
      const TransactionScreen(),
      const StatisticsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ✅ called from HomeScreen's "View All" button
  void _goToTransactions() {
    setState(() {
      _selectedIndex = 1; // index for Transaction tab
    });
  }

  void _showAddTransactionModal() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const AddTransactionScreen();
      },
    );

    if (result == true) {
      // ✅ refresh HomeScreen data after adding transaction
      _homeKey.currentState?.fetchDataAndUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionModal,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildNavItem(icon: Icons.home, text: 'Home', index: 0),
                  _buildNavItem(
                    icon: Icons.list_alt,
                    text: 'Transaction',
                    index: 1,
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildNavItem(
                    icon: Icons.pie_chart,
                    text: 'Statistics',
                    index: 2,
                  ),
                  _buildNavItem(icon: Icons.person, text: 'Profile', index: 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for bottom nav items
  Widget _buildNavItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.blueAccent : Colors.grey;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
