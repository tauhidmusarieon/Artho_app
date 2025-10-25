import 'package:artho_app/OnboardingScreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      home: OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
