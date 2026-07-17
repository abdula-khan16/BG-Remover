import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/constants.dart';
import '../utils/image_storage_helper.dart';

class RecentsEditsScreen extends StatefulWidget {
  const RecentsEditsScreen({super.key});

  @override
  State<RecentsEditsScreen> createState() => _RecentsEditsScreenState();
}

class _RecentsEditsScreenState extends State<RecentsEditsScreen> {
  List<String> _savedPaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final paths = await ImageStorageHelper.getSavedImages();
    if (mounted) {
      setState(() {
        _savedPaths = paths;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteImage(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This will permanently remove this edit from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ImageStorageHelper.deleteImage(path);
      _loadImages();
    }
  }

  Future<void> _shareImage(String path) async {
    try {
      await Share.shareXFiles([XFile(path)], text: 'Check out my background removal! 🎨');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(AppStrings.recentEdits),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadImages,
                child: _savedPaths.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _savedPaths.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          return _buildRecentImageCard(_savedPaths[index]);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_outlined, size: 64, color: AppColors.primary.withOpacity(0.5)),
              ),
              const SizedBox(height: 24),
              const Text(
                AppStrings.noHistory,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.noHistorySub,
                style: TextStyle(color: AppColors.gray),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentImageCard(String filePath) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with Fade-in
          Image.file(
            File(filePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.grayLight,
              child: const Icon(Icons.broken_image, color: AppColors.gray, size: 40),
            ),
          ),

          // Delete Button (Top Right)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _deleteImage(filePath),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),

          // Share Button (Bottom Right)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _shareImage(filePath),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
