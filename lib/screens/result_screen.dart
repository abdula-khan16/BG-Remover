import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../utils/constants.dart';

class ResultScreen extends StatefulWidget {
  final File resultImage;
  final File originalImage;

  const ResultScreen({
    super.key,
    required this.resultImage,
    required this.originalImage,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _isSharing = false;

  // ========== SAVE TO GALLERY (FIXED) ==========
  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      // ✅ CORRECT: Read image as bytes
      final bytes = await widget.resultImage.readAsBytes();

      // ✅ CORRECT: saveImage expects bytes, not file path
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,  // ✅ Pass bytes, NOT file path
        quality: 100,
        name: 'bg_removed_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result != null) {
        _showSnackBar('✅ Saved to Gallery!', Colors.green);
      } else {
        _showSnackBar('❌ Failed to save image', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ========== SHARE ==========
  Future<void> _shareImage() async {
    setState(() => _isSharing = true);
    try {
      final xFile = XFile(widget.resultImage.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Check out my background removed image! Made with BG Eraser 🎨',
      );
    } catch (e) {
      _showSnackBar('❌ Error sharing: $e', Colors.red);
    } finally {
      setState(() => _isSharing = false);
    }
  }

  // ========== GO HOME ==========
  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
          (route) => false,
    );
  }

  // ========== ✅ ADD THIS MISSING METHOD ==========
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========== FILE SIZE HELPER ==========
  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goHome,
          ),
        ],
      ),
      body: Column(
        children: [
          // ========== IMAGE ==========
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.resultImage,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ========== INFO ==========
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  label: 'File Size',
                  value: _getFileSize(widget.resultImage),
                ),
                const Divider(),
                _buildInfoRow(
                  label: 'Format',
                  value: 'PNG with Transparency',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ========== BUTTONS ==========
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveToGallery,
                    icon: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.download),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareImage,
                    icon: _isSharing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.share),
                    label: Text(_isSharing ? 'Sharing...' : 'Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ========== NEW IMAGE ==========
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goHome,
                icon: const Icon(Icons.refresh),
                label: const Text('New Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ========== INFO ROW HELPER ==========
  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}