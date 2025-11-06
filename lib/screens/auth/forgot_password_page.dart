import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email.')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    String? snackbarMessage; 

    try {
      // Check if the email is registered
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        email,
      );

      // If the 'methods' list is empty, it means no account has been opened with this email.
      if (methods.isEmpty) {
        snackbarMessage = 'No user found with this email.';
      } else {
        // If the list is not empty, it means there are users. Now the reset link is being sent.
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        snackbarMessage = 'Password reset email sent. Check your inbox.';

        if (mounted) {
          Navigator.of(context).pop(); 
        }
      }
    } on FirebaseAuthException catch (e) {
      // Other errors (e.g., email format incorrect, network problem)
      if (e.code == 'invalid-email') {
        snackbarMessage = 'The email address is badly formatted.';
      } else {
        snackbarMessage = e.message ?? 'An unknown error occurred.';
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show message after completion of task (success or failure)
        if (snackbarMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(249, 239, 194, 1),
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Forgot your password?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "No problem. Enter your email address below and we'll send you a link to reset it.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: "Email",
                hintText: "Enter your registered email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendPasswordResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send Reset Link"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
