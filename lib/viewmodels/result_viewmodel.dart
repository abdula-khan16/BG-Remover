import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';

class ResultViewModel extends GetxController {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isSharing = false;
  bool get isSharing => _isSharing;

  Future<void> saveToGallery(File resultImage, {required Function(String, Color) onMessage}) async {
    _isSaving = true;
    update();
    try {
      final bytes = await resultImage.readAsBytes();
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'bg_removed_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result != null) {
        onMessage('✅ Saved to Gallery!', Colors.green);
      } else {
        onMessage('❌ Failed to save image', Colors.red);
      }
    } catch (e) {
      onMessage('❌ Error: $e', Colors.red);
    } finally {
      _isSaving = false;
      update();
    }
  }

  Future<void> shareImage(File resultImage, {required Function(String, Color) onMessage}) async {
    _isSharing = true;
    update();
    try {
      final xFile = XFile(resultImage.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Check out my background removed image! Made with BG Eraser 🎨',
      );
    } catch (e) {
      onMessage('❌ Error sharing: $e', Colors.red);
    } finally {
      _isSharing = false;
      update();
    }
  }

  String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
