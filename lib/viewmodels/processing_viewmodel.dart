import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/background_remover_services.dart';
import '../utils/image_storage_helper.dart';

class ProcessingViewModel extends GetxController {
  final BackgroundRemoverService _remover = BackgroundRemoverService();
  
  double _progress = 0.0;
  double get progress => _progress;

  String _status = 'Loading AI Model...';
  String get status => _status;

  bool _isProcessing = true;
  bool get isProcessing => _isProcessing;

  String? _error;
  String? get error => _error;

  void retry(String imagePath, Function(File) onProcessComplete) {
    _error = null;
    _progress = 0.0;
    _status = 'Retrying...';
    _isProcessing = true;
    update();
    processImage(imagePath, onProcessComplete);
  }

  Future<void> _autoSyncToCloud(File file) async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      final prefs = await SharedPreferences.getInstance();
      final bool isGuest = prefs.getBool('isGuest') ?? false;

      if (session != null && !isGuest) {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          final fileName = file.path.split('/').last;
          final userId = session.user.id;
          
          _status = 'Syncing to cloud...';
          update();
          
          await supabase.storage.from('edits').upload(
            '$userId/$fileName',
            file,
            fileOptions: const FileOptions(upsert: true),
          );
          debugPrint('✅ Auto-synced to Supabase');
        }
      }
    } catch (e) {
      debugPrint('❌ Auto-sync failed: $e');
    }
  }

  Future<void> processImage(String imagePath, Function(File) onProcessComplete) async {
    try {
      // Step 1: Load Model (0-30%)
      _progress = 0.1;
      _status = 'Loading AI Model...';
      update();

      await _remover.loadModel();

      _progress = 0.3;
      _status = 'Analyzing image...';
      update();

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Process Image (30-80%)
      _progress = 0.5;
      _status = 'Removing background...';
      update();

      final resultFile = await _remover.removeBackground(imagePath);

      _progress = 0.8;
      _status = 'Saving locally...';
      update();

      // SAVE TO PERMANENT LOCAL STORAGE
      final bytes = await resultFile.readAsBytes();
      final permanentPath = await ImageStorageHelper.saveImage(bytes);
      final permanentFile = File(permanentPath);

      // ATTEMPT AUTO-SYNC IF LOGGED IN & ONLINE
      await _autoSyncToCloud(permanentFile);

      _progress = 1.0;
      _status = 'Done! ✨';
      _isProcessing = false;
      update();

      await Future.delayed(const Duration(milliseconds: 500));
      onProcessComplete(permanentFile);
    } catch (e) {
      _error = e.toString();
      _isProcessing = false;
      _status = '❌ Failed: $e';
      update();
    }
  }

  @override
  void onClose() {
    _remover.dispose();
    super.onClose();
  }
}
