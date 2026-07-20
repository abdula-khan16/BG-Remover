import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashViewModel extends GetxController {
  Future<String> initializeApp() async {
    // 1. Splash delay (animation/branding)
    await Future.delayed(const Duration(seconds: 2));

    // 2. Check if it's the user's first time ever
    final prefs = await SharedPreferences.getInstance();
    final bool showOnboarding = prefs.getBool('showOnboarding') ?? true;

    if (showOnboarding) {
      return '/onboarding';
    }

    // 3. Check if user is already authenticated
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return '/home';
    } else {
      return '/login';
    }
  }
}
