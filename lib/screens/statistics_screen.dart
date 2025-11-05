import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(70.0),
          child: Text(
            'Idea in progress... brain buffering at 23%. 🧠💫',
            style: TextStyle(fontSize: 25, color: Colors.black),
          ),
        ),
      ),
      // TODO: এখানে গ্রাফ দেখানো হবে
    );
  }
}
