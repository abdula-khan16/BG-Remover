import 'dart:io';
import 'package:bg_remover_demo/screens/settings_screen.dart';
import 'package:bg_remover_demo/screens/recents_edits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../viewmodels/home_viewmodel.dart';
import 'preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeViewModel _viewModel = Get.put(HomeViewModel());

  @override
  void initState() {
    super.initState();
    _viewModel.loadRecentImages();
  }

  void _showPermissionDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: GetBuilder<HomeViewModel>(
          builder: (controller) {
            return RefreshIndicator(
              onRefresh: controller.loadRecentImages,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ========== HEADER ==========
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    AppStrings.appName,
                                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings, color: Colors.white),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            AppStrings.appTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppStrings.appSubtitle,
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.camera_alt,
                                  label: 'Camera',
                                  onTap: () async {
                                    final path = await controller.takePhoto(
                                      onPermissionRequired: _showPermissionDialog,
                                      onMessage: _showSnackBar,
                                    );
                                    if (path != null && mounted) {
                                      await Navigator.push(context, MaterialPageRoute(builder: (context) => PreviewScreen(imagePath: path)));
                                      controller.loadRecentImages();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.photo_library,
                                  label: 'Gallery',
                                  onTap: () async {
                                    final path = await controller.pickFromGallery(onMessage: _showSnackBar);
                                    if (path != null && mounted) {
                                      await Navigator.push(context, MaterialPageRoute(builder: (context) => PreviewScreen(imagePath: path)));
                                      controller.loadRecentImages();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ========== FEATURES SESSION ==========
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFeatureCard(Icons.bolt, 'Fast', isDarkMode),
                          _buildFeatureCard(Icons.security, 'Secure', isDarkMode),
                          _buildFeatureCard(Icons.hd, 'HD Quality', isDarkMode),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ========== RECENTS ==========
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Recent Edits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentsEditsScreen())),
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          controller.isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : controller.recentPaths.isEmpty 
                              ? _buildEmptyState()
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: controller.recentPaths.length > 4 ? 4 : controller.recentPaths.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1,
                                  ),
                                  itemBuilder: (context, index) => _buildRecentCard(controller.recentPaths[index]),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label, bool isDarkMode) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRecentCard(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(File(path), fit: BoxFit.cover),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AppColors.grayLight, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        children: [
          Icon(Icons.image_search, size: 48, color: AppColors.gray),
          SizedBox(height: 12),
          Text('No edits yet', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
