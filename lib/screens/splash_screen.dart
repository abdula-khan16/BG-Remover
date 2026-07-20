import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../viewmodels/splash_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashViewModel _viewModel = Get.put(SplashViewModel());

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final route = await _viewModel.initializeApp();
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
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
