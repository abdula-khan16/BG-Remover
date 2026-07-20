import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../viewmodels/sign_up_viewmodel.dart';
import 'privacy_policy_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SignUpViewModel _viewModel = Get.put(SignUpViewModel());

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ========== GUEST MODE ==========
  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: GetBuilder<SignUpViewModel>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Image.asset("assets/images/logo.png", height: 100)),
                const SizedBox(height: 20),
                Center(
                  child: const Text(
                    'Create account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 30),

                // FIRST NAME FIELD
                TextField(
                  controller: controller.firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // LAST NAME FIELD
                TextField(
                  controller: controller.lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // EMAIL FIELD
                TextField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // PASSWORD FIELD
                TextField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword,
                  onChanged: controller.checkPasswordStrength,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                ),
                if (controller.passwordStrength.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(controller.passwordStrength, style: TextStyle(color: controller.passwordStrengthColor, fontSize: 12)),
                  ),
                
                const SizedBox(height: 20),
                
                // TERMS
                Row(
                  children: [
                    Checkbox(
                      value: controller.agreeToTerms,
                      checkColor: Colors.white,
                      onChanged: (v) => controller.setAgreeToTerms(v ?? false),
                    ),
                    const Expanded(child: Text('I agree to the Terms of Service', style: TextStyle(color: Colors.grey))),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // SIGN UP BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () async {
                            final success = await controller.signUp(onMessage: _showSnackBar);
                            if (success && mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 16),

                // ========== GUEST BUTTON ==========
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: controller.isLoading ? null : _continueAsGuest,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('Continue as Guest', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                // ========== PRIVACY POLICY ==========
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      );
                    },
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
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
