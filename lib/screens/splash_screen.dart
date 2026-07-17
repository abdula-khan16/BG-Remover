import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Splash delay (animation/branding)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. Check if it's the user's first time ever
    final prefs = await SharedPreferences.getInstance();
    final bool showOnboarding = prefs.getBool('showOnboarding') ?? true;

    if (showOnboarding) {
      // First time -> Onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    // 3. Check if user is already authenticated
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Already logged in -> Home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Returning but not logged in -> Login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              "BG Eraser",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            CircularProgressIndicator(
              color: Colors.white.withOpacity(0.5),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
