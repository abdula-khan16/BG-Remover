import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: July 2026\n\n'
              'Welcome to BG Eraser! Your privacy is critically important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our app.\n\n'
              '1. Information We Collect\n'
              'We may collect information you provide directly to us, such as your email address and profile photo when you sign up for an account. Images you edit are processed securely and may be temporarily or permanently stored on our servers if you choose to sync them.\n\n'
              '2. How We Use Your Information\n'
              'We use the information we collect to operate, maintain, and provide the features and functionality of the app, as well as to communicate directly with you, such as to send you email messages regarding your account.\n\n'
              '3. Google Data\n'
              'If you choose to sign in with Google, we will access your Google account email and basic profile information solely for authentication purposes.\n\n'
              '4. Data Security\n'
              'We use commercially reasonable physical, managerial, and technical safeguards to preserve the integrity and security of your personal information. However, no method of transmission over the Internet is 100% secure.\n\n'
              '5. Changes to Our Privacy Policy\n'
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.\n\n'
              'If you have any questions about this Privacy Policy, please contact us at support@bgeraser.demo.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
