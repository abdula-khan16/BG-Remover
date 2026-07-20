import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../viewmodels/login_viewmodel.dart';
import 'privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginViewModel _viewModel = Get.put(LoginViewModel());

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GetBuilder<LoginViewModel>(
          builder: (controller) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Image.asset("assets/images/logo.png", height: 100)),
                  const SizedBox(height: 20),
                  Center(child: const Text('Welcome back',textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,color: AppColors.primary))),
                  const SizedBox(height: 30),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.passwordController,
                    obscureText: controller.obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(controller.obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => controller.forgotPassword(onMessage: _showSnackBar),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              final success = await controller.login(onMessage: _showSnackBar);
                              if (success && mounted) {
                                Navigator.pushReplacementNamed(context, '/home');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: controller.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ========== GUEST BUTTON ==========
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              final success = await controller.continueAsGuest();
                              if (success && mounted) {
                                Navigator.pushReplacementNamed(context, '/home');
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Continue as Guest', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ========== GOOGLE SIGN IN ==========
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              final success = await controller.signInWithGoogle(onMessage: _showSnackBar);
                              if (success && mounted) {
                                Navigator.pushReplacementNamed(context, '/home');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                      icon: Image.asset(
                        'assets/images/google.png',
                        height: 24,
                      ),
                      label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",style: TextStyle(color: AppColors.black),),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text('Sign up', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  // ========== PRIVACY POLICY ==========
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      );
                    },
                    child: Center(
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

