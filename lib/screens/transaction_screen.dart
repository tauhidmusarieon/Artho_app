import 'package:flutter/material.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: const Center(child: Padding(
        padding: EdgeInsets.all(70.0),
        child: Text('Feature paused. Developer battery at 1% — send snacks. 🍕⚡', style: TextStyle(fontSize: 25,color: Colors.black),),
      )),
      // TODO: এখানে সব ট্রানজ্যাকশন দেখানো হবে
    );
  }
}
