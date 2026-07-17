import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../utils/constants.dart';
import 'processing_screen.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  // extended_image ^10.1.0 uses ImageEditorController instead of a
  // GlobalKey<ExtendedImageEditorState> to drive rotate/flip/reset and to
  // read back the crop rect + edit actions.
  final ImageEditorController _editorController = ImageEditorController();

  bool _isSaving = false;

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  // ========== ROTATE / FLIP / RESET HELPERS ==========
  void _rotate(bool right) {
    // Note: the shipped API in 10.1.0 names this parameter `degree`
    // (singular), not `degrees` as the README examples show.
    _editorController.rotate(degree: right ? 90 : -90);
  }

  void _flip() {
    _editorController.flip();
  }

  void _reset() {
    _editorController.reset();
  }

  // ========== BAKE THE EDIT INTO A REAL IMAGE FILE ==========
  Future<String?> _exportEditedImage() async {
    final ExtendedImageEditorState? state = _editorController.state;
    final EditActionDetails? action = _editorController.editActionDetails;
    if (state == null || action == null) return null;

    final Rect? cropRect = _editorController.getCropRect();

    final Uint8List rawBytes = state.rawImageData;
    img.Image? src = img.decodeImage(rawBytes);
    if (src == null) return null;

    // Clear any embedded EXIF orientation first, same as extended_image's
    // own example, so rotate/flip/crop below operate on "upright" pixels.
    src = img.bakeOrientation(src);

    // Apply rotation
    if (action.hasRotateDegrees) {
      src = img.copyRotate(src, angle: action.rotateDegrees);
    }

    // Apply flip (only horizontal flip exists as of extended_image 9+)
    if (action.flipY) {
      src = img.flip(src, direction: img.FlipDirection.horizontal);
    }

    // Apply crop
    if (action.needCrop && cropRect != null) {
      src = img.copyCrop(
        src,
        x: cropRect.left.toInt().clamp(0, src.width - 1),
        y: cropRect.top.toInt().clamp(0, src.height - 1),
        width: cropRect.width.toInt().clamp(1, src.width),
        height: cropRect.height.toInt().clamp(1, src.height),
      );
    }

    final Uint8List outBytes = Uint8List.fromList(img.encodePng(src));

    final Directory tempDir = await getTemporaryDirectory();
    final String outPath =
        '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
    final File outFile = File(outPath);
    await outFile.writeAsBytes(outBytes);

    return outPath;
  }

  Future<void> _onProcessPressed() async {
    setState(() => _isSaving = true);

    final String? editedPath = await _exportEditedImage();

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (editedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not process the edit. Try again.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          imagePath: editedPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ========== IMAGE EDITOR (crop / rotate / scale) ==========
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                child: ExtendedImage.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.editor,
                  cacheRawData: true,
                  initEditorConfigHandler: (state) {
                    return EditorConfig(
                      // free-form crop; pass a value like 1.0 to lock a
                      // square crop, or leave null for free aspect ratio
                      cropAspectRatio: null,
                      cropRectPadding: const EdgeInsets.all(20),
                      hitTestSize: 20,
                      controller: _editorController,
                    );
                  },
                ),
              ),
            ),
          ),

          // ========== EDITOR TOOLBAR ==========
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.rotate_left, color: Colors.white),
                  tooltip: 'Rotate left',
                  onPressed: () => _rotate(false),
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right, color: Colors.white),
                  tooltip: 'Rotate right',
                  onPressed: () => _rotate(true),
                ),
                IconButton(
                  icon: const Icon(Icons.flip, color: Colors.white),
                  tooltip: 'Flip',
                  onPressed: _flip,
                ),
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.white),
                  tooltip: 'Reset',
                  onPressed: _reset,
                ),
              ],
            ),
          ),

          // ========== INFO TEXT ==========
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Crop, rotate, or scale, then tap "Process" to remove the background',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ========== PROCESS BUTTON ==========
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onProcessPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high),
                    SizedBox(width: 12),
                    Text(
                      'Process',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ========== CANCEL BUTTON ==========
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}