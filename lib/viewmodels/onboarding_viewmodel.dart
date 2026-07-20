import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingViewModel extends GetxController {
  Future<String> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
    return '/login';
  }
}
