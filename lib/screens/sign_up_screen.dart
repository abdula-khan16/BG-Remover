import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ========== CONTROLLERS ==========
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ========== STATE ==========
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  String _passwordStrength = '';
  Color _passwordStrengthColor = Colors.grey;

  // Access Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  // ========== PASSWORD STRENGTH CHECK ==========
  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    setState(() {
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
    });
  }

  // ========== SIGN UP WITH EMAIL ==========
  Future<void> _signUp() async {
    if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your first and last name', Colors.red);
      return;
    }
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.red);
      return;
    }
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to terms', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
        },
      );

      if (response.user != null) {
        _showSnackBar('✅ Success! Please verify your email.', Colors.green);
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // FIRST NAME FIELD
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // LAST NAME FIELD
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            // EMAIL FIELD
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            // PASSWORD FIELD
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: _checkPasswordStrength,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            if (_passwordStrength.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_passwordStrength, style: TextStyle(color: _passwordStrengthColor, fontSize: 12)),
              ),
            
            const SizedBox(height: 20),
            
            // TERMS
            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                ),
                const Expanded(child: Text('I agree to the Terms of Service')),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // SIGN UP BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account'),
              ),
            ),
            
            const SizedBox(height: 20),
            

          ],
        ),
      ),
    );
  }
}
