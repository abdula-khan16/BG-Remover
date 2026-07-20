import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/image_storage_helper.dart';

class ProfileViewModel extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  User? _user;
  User? get user => _user;

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  List<String> _recentPaths = [];
  List<String> get recentPaths => _recentPaths;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    _isLoading = true;
    update();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool('isGuest') ?? false;
      
      if (!_isGuest) {
        _user = _supabase.auth.currentUser;
        if (_user == null) {
          _isGuest = true;
        }
      }

      // Load local images immediately so UI renders
      _recentPaths = await ImageStorageHelper.getSavedImages();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _isLoading = false;
      update();
    }

    // Trigger cloud sync in background if not guest
    if (!_isGuest && _user != null) {
      _syncAndReload();
    }
  }

  Future<void> _syncAndReload() async {
    await ImageStorageHelper.syncCloudEdits();
    _recentPaths = await ImageStorageHelper.getSavedImages();
    update();
  }

  String getUserName() {
    if (_isGuest || _user == null) return 'Guest User';
    final metadata = _user!.userMetadata;
    if (metadata != null) {
      final fullName = metadata['full_name'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }
      final firstName = metadata['first_name'] as String?;
      final lastName = metadata['last_name'] as String?;
      if (firstName != null && firstName.trim().isNotEmpty) {
        return '${firstName.trim()} ${lastName?.trim() ?? ''}'.trim();
      }
    }
    final email = _user!.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'User Name';
  }

  String? get avatarUrl {
    if (_isGuest || _user == null) return null;
    final metadata = _user!.userMetadata;
    if (metadata != null && metadata.containsKey('avatar_url')) {
      return metadata['avatar_url'] as String?;
    }
    return null;
  }

  // ========== SYNC ALL UNSYNCED IMAGES ==========
  Future<void> uploadUnsyncedImages({required Function(String, Color) onMessage}) async {
    if (_isGuest || _user == null) {
      onMessage('Please login to sync with cloud', Colors.orange);
      return;
    }

    final unsynced = await ImageStorageHelper.getUnsyncedImages();
    if (unsynced.isEmpty) {
      onMessage('✅ All images are already synced!', Colors.green);
      return;
    }

    _isUploading = true;
    update();

    int successCount = 0;
    try {
      for (String path in unsynced) {
        try {
          final file = File(path);
          final fileName = path.split('/').last;
          final storagePath = '${_user!.id}/$fileName';

          await _supabase.storage.from('edits').upload(
                storagePath,
                file,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
              );
          
          await ImageStorageHelper.markAsSynced(path);
          successCount++;
        } catch (e) {
          debugPrint('Failed to sync $path: $e');
        }
      }
      
      if (successCount > 0) {
        onMessage('✅ Successfully synced $successCount images!', Colors.green);
      } else {
        onMessage('❌ Sync failed. Please check your connection.', Colors.red);
      }
    } finally {
      _isUploading = false;
      update();
    }
  }

  Future<void> uploadImage(String filePath, {required Function(String, Color) onMessage}) async {
    if (_isGuest || _user == null) {
      onMessage('Please login to sync with cloud', Colors.orange);
      return;
    }
    
    _isUploading = true;
    update();
    try {
      final file = File(filePath);
      final fileName = filePath.split('/').last;
      final path = '${_user!.id}/$fileName';

      await _supabase.storage.from('edits').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      await ImageStorageHelper.markAsSynced(filePath);
      onMessage('✅ Image synced to cloud!', Colors.green);
    } catch (e) {
      onMessage('❌ Upload failed: $e', Colors.red);
    } finally {
      _isUploading = false;
      update();
    }
  }

  Future<bool> signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isGuest ? 'Exit Guest Mode' : 'Sign Out'),
        content: Text(_isGuest ? 'Are you sure you want to exit?' : 'Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isGuest ? 'Exit' : 'Sign Out', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!_isGuest) await _supabase.auth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuest', false);
      return true;
    }
    return false;
  }
}
