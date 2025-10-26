import 'package:artho_app/on_boarding_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      home: on_boarding_screen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
