import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/image_storage_helper.dart';

class RecentsEditsViewModel extends GetxController {
  List<String> _savedPaths = [];
  List<String> get savedPaths => _savedPaths;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadImages() async {
    _savedPaths = await ImageStorageHelper.getSavedImages();
    _isLoading = false;
    update();
  }

  Future<void> deleteImage(BuildContext context, String path) async {
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
      await loadImages();
    }
  }

  Future<void> shareImage(String path, {required Function(String, Color) onMessage}) async {
    try {
      await Share.shareXFiles([XFile(path)], text: 'Check out my background removal! 🎨');
    } catch (e) {
      onMessage('Error sharing: $e', Colors.red);
    }
  }
}
