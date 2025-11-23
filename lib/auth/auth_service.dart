import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _keyEmail = 'auth_email';
  static const String _keyPassword =
      'auth_password'; // ⚠️ Not secure for production
  static const String _keyRememberMe = 'auth_remember_me';

  // Login with Email & Password
  Future<User?> login(String email, String password, bool rememberMe) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (rememberMe) {
        await _saveCredentials(email, password);
      } else {
        await _clearCredentials();
      }

      return result.user;
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Check if user is logged in
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Save credentials (if Remember Me is checked)
  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyRememberMe, true);
  }

  // Clear credentials
  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.setBool(_keyRememberMe, false);
  }

  // Get saved credentials for auto-fill
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (!rememberMe) return null;

    final email = prefs.getString(_keyEmail);
    final password = prefs.getString(_keyPassword);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
