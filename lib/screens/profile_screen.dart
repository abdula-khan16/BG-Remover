import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileViewModel>(
      init: ProfileViewModel(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(controller.isGuest ? Icons.login : Icons.logout, color: Colors.white),
                onPressed: () async {
                  final loggedOut = await controller.signOut(context);
                  if (loggedOut && context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                tooltip: controller.isGuest ? 'Login' : 'Logout',
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
            child: Column(
              children: [
                // ========== HEADER / USER INFO ==========
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: controller.avatarUrl != null
                            ? NetworkImage(controller.avatarUrl!)
                            : null,
                        child: controller.avatarUrl == null
                            ? Icon(
                                controller.isGuest ? Icons.person_outline : Icons.person,
                                size: 60,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.getUserName(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.isGuest ? 'Limited access mode' : (controller.user?.email ?? 'email@example.com'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ========== STATS (FEATURE SESSION) ==========
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(context, 'Local Edits', '${controller.recentPaths.length}'),
                      _buildStatCard(context, 'Cloud Sync', controller.isGuest ? 'Off' : 'Active'),
                      _buildStatCard(context, 'Plan', controller.isGuest ? 'Guest' : 'Free'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ========== COMMON SYNC BUTTON ==========
                if (!controller.isGuest)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSyncTile(context, controller),
                  ),

                const SizedBox(height: 32),

                // ========== RECENT EDITS SECTION ==========
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Recent Edits',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      controller.recentPaths.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.recentPaths.length > 6 ? 6 : controller.recentPaths.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemBuilder: (context, index) {
                                final path = controller.recentPaths[index];
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          );
        }
      );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncTile(BuildContext context, ProfileViewModel controller) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.cloud_sync, color: AppColors.primary, size: 30),
        title: const Text('Sync Unsynced Edits', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Upload local history to cloud'),
        trailing: controller.isUploading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: controller.isUploading ? null : () => controller.uploadUnsyncedImages(onMessage: (msg, color) => _showSnackBar(context, msg, color)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.image_outlined, size: 48, color: AppColors.gray),
          SizedBox(height: 16),
          Text('No edits yet', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
