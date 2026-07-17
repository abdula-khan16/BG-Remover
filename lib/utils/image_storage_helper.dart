import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageStorageHelper {
  static const String _storageKey = 'saved_edits_paths';
  static const String _syncedKey = 'synced_edits_paths';

  /// Saves the image bytes to the Application Documents Directory and updates SharedPreferences.
  static Future<String> saveImage(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String filePath = '${directory.path}/bg_removed_$timestamp.png';

    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPaths = prefs.getStringList(_storageKey) ?? [];
    savedPaths.insert(0, filePath); // Add to the beginning of the list
    await prefs.setStringList(_storageKey, savedPaths);

    return filePath;
  }

  /// Saves the image bytes to the Application Documents Directory with a specific filename and updates SharedPreferences.
  static Future<String> saveImageWithFilename(Uint8List bytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$filename';

    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPaths = prefs.getStringList(_storageKey) ?? [];
    if (!savedPaths.contains(filePath)) {
      savedPaths.insert(0, filePath); // Add to the beginning of the list
      await prefs.setStringList(_storageKey, savedPaths);
    }

    return filePath;
  }

  /// Retrieves the list of saved file paths from SharedPreferences.
  static Future<List<String>> getSavedImages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storageKey) ?? [];
  }

  /// Deletes an image from storage and removes it from SharedPreferences.
  static Future<void> deleteImage(String filePath) async {
    final File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPaths = prefs.getStringList(_storageKey) ?? [];
    savedPaths.remove(filePath);
    await prefs.setStringList(_storageKey, savedPaths);

    // Also remove from synced list
    List<String> syncedPaths = prefs.getStringList(_syncedKey) ?? [];
    syncedPaths.remove(filePath);
    await prefs.setStringList(_syncedKey, syncedPaths);
  }

  /// Marks a file as synced.
  static Future<void> markAsSynced(String filePath) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> syncedPaths = prefs.getStringList(_syncedKey) ?? [];
    if (!syncedPaths.contains(filePath)) {
      syncedPaths.add(filePath);
      await prefs.setStringList(_syncedKey, syncedPaths);
    }
  }

  /// Checks if a file is already synced.
  static Future<bool> isSynced(String filePath) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> syncedPaths = prefs.getStringList(_syncedKey) ?? [];
    return syncedPaths.contains(filePath);
  }

  /// Gets all images that haven't been synced yet.
  static Future<List<String>> getUnsyncedImages() async {
    final all = await getSavedImages();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final synced = prefs.getStringList(_syncedKey) ?? [];
    return all.where((path) => !synced.contains(path)).toList();
  }

  /// Syncs cloud edits from Supabase Storage edits bucket.
  static Future<void> syncCloudEdits() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        return;
      }

      // List files under the user's directory in the edits bucket
      final List<FileObject> objects = await supabase.storage.from('edits').list(path: user.id);

      final directory = await getApplicationDocumentsDirectory();

      for (final obj in objects) {
        final filename = obj.name;
        // Ignore folder placeholders/empty names if any
        if (filename.isEmpty || filename == '.placeholder') continue;

        final localPath = '${directory.path}/$filename';
        final file = File(localPath);

        // Download if it does not exist locally
        if (!await file.exists()) {
          try {
            final Uint8List bytes = await supabase.storage.from('edits').download('${user.id}/$filename');
            await saveImageWithFilename(bytes, filename);
          } catch (e) {
            // Log error and continue to the next file
            print('Error downloading file $filename: $e');
          }
        }

        // Mark it as synced locally in SharedPreferences
        await markAsSynced(localPath);
      }
    } catch (e) {
      print('Error during syncCloudEdits: $e');
    }
  }

  /// Clears all local edits from SharedPreferences and deletes their files.
  static Future<void> clearLocalEdits() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> savedPaths = prefs.getStringList(_storageKey) ?? [];
      
      for (final path in savedPaths) {
        final file = File(path);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            print('Error deleting file on logout: $e');
          }
        }
      }
      
      await prefs.remove(_storageKey);
      await prefs.remove(_syncedKey);
    } catch (e) {
      print('Error clearing local edits: $e');
    }
  }
}
