import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:websit/admin_dashboard/admin_dashboard.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If logged in
        if (snapshot.hasData) {
          return const AdminDashboard();
        }

        // If not logged in
        return const LoginPage();
      },
    );
  }
}
