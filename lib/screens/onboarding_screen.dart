import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(OnboardingViewModel());
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.auto_awesome, size: 100, color: AppColors.primary),
              const SizedBox(height: 40),
              const Text(
                AppStrings.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.appSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.gray),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final route = await viewModel.completeOnboarding();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, route);
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Get Started", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
