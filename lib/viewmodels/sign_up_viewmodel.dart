import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;
import 'package:shared_preferences/shared_preferences.dart';

class SignUpViewModel extends GetxController {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _agreeToTerms = false;
  bool get agreeToTerms => _agreeToTerms;

  String _passwordStrength = '';
  String get passwordStrength => _passwordStrength;

  Color _passwordStrengthColor = Colors.grey;
  Color get passwordStrengthColor => _passwordStrengthColor;

  final SupabaseClient _supabase = Supabase.instance.client;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    update();
  }

  void setAgreeToTerms(bool value) {
    _agreeToTerms = value;
    update();
  }

  void checkPasswordStrength(String password) {
    if (password.isEmpty) {
      _passwordStrength = '';
      _passwordStrengthColor = Colors.grey;
      update();
      return;
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) {
      _passwordStrength = 'Weak';
      _passwordStrengthColor = Colors.red;
    } else if (score == 3) {
      _passwordStrength = 'Moderate';
      _passwordStrengthColor = Colors.orange;
    } else {
      _passwordStrength = 'Strong! 💪';
      _passwordStrengthColor = Colors.green;
    }
    update();
  }

  Future<bool> signUp({required Function(String, Color) onMessage}) async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      onMessage('Please enter your first and last name', Colors.red);
      return false;
    }
    if (email.isEmpty || password.isEmpty) {
      onMessage('Please fill in all fields', Colors.red);
      return false;
    }
    if (!_agreeToTerms) {
      onMessage('Please agree to terms', Colors.red);
      return false;
    }

    _isLoading = true;
    update();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName'.trim(),
        },
      );

      if (response.user != null) {
        onMessage('✅ Success! Please verify your email.', Colors.green);
        return true;
      }
      return false;
    } catch (e) {
      onMessage('❌ Error: $e', Colors.red);
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> signInWithGoogle({required Function(String, Color) onMessage}) async {
    _isLoading = true;
    update();

    try {
      const webClientId = '443150406281-8s3sb90hrfd3m0j5m3v5fmgfolnn3qgj.apps.googleusercontent.com';

      final googleSignIn = google.GoogleSignIn.instance;

      await googleSignIn.initialize(serverClientId: webClientId);

      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final idToken = googleAuth.idToken;
      final accessToken = authorization?.accessToken;

      if (idToken == null) {
        onMessage('❌ Google sign up aborted.', Colors.red);
        return false;
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGuest', false);
        return true;
      }
      return false;
    } catch (e) {
      onMessage('❌ Error signing up with Google: $e', Colors.red);
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }
  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

