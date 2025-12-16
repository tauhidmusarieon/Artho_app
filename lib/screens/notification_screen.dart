import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Monthly Report Ready'),
            subtitle: const Text('Tap to download & share'),
            onTap: () {
              // future: open or download PDF
            },
          ),
        ],
      ),
    );
  }
}
