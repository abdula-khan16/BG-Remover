import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the view model
    final SettingsViewModel _viewModel = Get.put(SettingsViewModel());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: GetBuilder<SettingsViewModel>(
        builder: (controller) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primary),
                title: const Text('My Profile'),
                subtitle: const Text('View profile details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: AppColors.primary),
                title: const Text('Dark Mode'),
                value: controller.isDarkMode,
                onChanged: controller.toggleTheme,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.primary),
                title: const Text('Rate Us'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help, color: AppColors.primary),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/help_support');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: AppColors.primary),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/privacy_policy');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
