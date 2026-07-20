import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/image_storage_helper.dart';

class HomeViewModel extends GetxController {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _recentPaths = [];
  List<String> get recentPaths => _recentPaths;

  final ImagePicker _picker = ImagePicker();

  Future<void> loadRecentImages() async {
    _recentPaths = await ImageStorageHelper.getSavedImages();
    update();
    await _syncCloudEditsInBackground();
  }

  Future<void> _syncCloudEditsInBackground() async {
    await ImageStorageHelper.syncCloudEdits();
    _recentPaths = await ImageStorageHelper.getSavedImages();
    update();
  }

  Future<String?> takePhoto({
    required Function(String, String) onPermissionRequired,
    required Function(String, Color) onMessage,
  }) async {
    try {
      final status = await Permission.camera.status;

      if (!status.isGranted) {
        final requested = await Permission.camera.request();

        if (!requested.isGranted) {
          onPermissionRequired(
            'Camera Permission Required',
            'BG Eraser needs camera access to take photos for background removal. Please grant permission in settings.',
          );
          return null;
        }
      }

      _isLoading = true;
      update();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (photo != null) {
        return photo.path;
      }
    } catch (e) {
      onMessage('Camera error: $e', Colors.red);
    } finally {
      _isLoading = false;
      update();
    }
    return null;
  }

  Future<String?> pickFromGallery({
    required Function(String, Color) onMessage,
  }) async {
    _isLoading = true;
    update();

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        return image.path;
      }
    } catch (e) {
      onMessage('Gallery error: $e', Colors.red);
    } finally {
      _isLoading = false;
      update();
    }
    return null;
  }
}
