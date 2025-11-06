import 'package:artho_app/on_boarding_screen.dart'; 
import 'package:artho_app/screens/main_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // user are login or not chacking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user is logged in
        if (snapshot.hasData) {
          return const MainScreen(); //go to the main  MainScreen
        }

        // If the user is not logged in
        return const on_boarding_screen(); // OnBoarding-
      },
    );
  }
}
