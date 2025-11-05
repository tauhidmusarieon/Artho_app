import 'package:artho_app/screens/add_transaction_screen.dart';
// ১. Import ঠিক করা হয়েছে
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

  // ২. GlobalKey-এর টাইপ ঠিক করা হয়েছে ( _HomeScreenState -> HomeScreenState )
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(key: _homeKey), // Key টি এখানে পাস করা হলো
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

    // যদি ট্রানজ্যাকশন সফলভাবে অ্যাড হয় (result == true)
    if (result == true) {
      // HomeScreen-কে রিফ্রেশ করতে বলা হচ্ছে
      // ৩. এই লাইনটি এখন HomeScreenState-কে খুঁজে পাবে
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

  // ন্যাভিগেশন আইটেম বানানোর একটি হেল্পার
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
