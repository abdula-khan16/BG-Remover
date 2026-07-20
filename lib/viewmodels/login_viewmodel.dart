import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;

class LoginViewModel extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  final SupabaseClient _supabase = Supabase.instance.client;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    update(); // Rebuilds GetBuilder<LoginViewModel>
  }

  Future<bool> login({required Function(String, Color) onMessage}) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      onMessage('Please enter email and password', Colors.red);
      return false;
    }

    _isLoading = true;
    update();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGuest', false);
        return true;
      }
      return false;
    } catch (e) {
      onMessage('❌ Invalid email or password. Please try again.', Colors.red);
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


  Future<bool> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    return true;
  }


  Future<void> forgotPassword({required Function(String, Color) onMessage}) async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      onMessage('Please enter your email address', Colors.red);
      return;
    }

    _isLoading = true;
    update();
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      onMessage('✅ Password reset email sent! Check your inbox.', Colors.green);
    } catch (e) {
      onMessage('❌ Error: $e', Colors.red);
    } finally {
      _isLoading = false;
      update();
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
