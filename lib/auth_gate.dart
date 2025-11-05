import 'package:artho_app/on_boarding_screen.dart'; // আপনার ফাইল
import 'package:artho_app/screens/main_screen.dart'; // আমরা এটি ধাপ ৩ এ তৈরি করবো
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ইউজার লগইন করছে কিনা তা চেক করার স্পিনার
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ইউজার লগইন করা থাকলে
        if (snapshot.hasData) {
          return const MainScreen(); // MainScreen-এ পাঠানো হচ্ছে
        }

        // ইউজার লগইন করা না থাকলে
        return const on_boarding_screen(); // OnBoarding-এ পাঠানো হচ্ছে
      },
    );
  }
}
