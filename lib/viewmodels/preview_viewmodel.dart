import 'dart:io';
import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class PreviewViewModel extends GetxController {
  final ImageEditorController editorController = ImageEditorController();
  
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  void rotate(bool right) {
    editorController.rotate(degree: right ? 90 : -90);
    update();
  }

  void flip() {
    editorController.flip();
    update();
  }

  void reset() {
    editorController.reset();
    update();
  }

  Future<String?> exportEditedImage() async {
    final ExtendedImageEditorState? state = editorController.state;
    final EditActionDetails? action = editorController.editActionDetails;
    if (state == null || action == null) return null;

    final Rect? cropRect = editorController.getCropRect();

    final Uint8List rawBytes = state.rawImageData;
    img.Image? src = img.decodeImage(rawBytes);
    if (src == null) return null;

    src = img.bakeOrientation(src);

    if (action.hasRotateDegrees) {
      src = img.copyRotate(src, angle: action.rotateDegrees);
    }

    if (action.flipY) {
      src = img.flip(src, direction: img.FlipDirection.horizontal);
    }

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

  Future<String?> processImage({required Function(String) onErrorMessage}) async {
    _isSaving = true;
    update();

    try {
      final String? editedPath = await exportEditedImage();
      if (editedPath == null) {
        onErrorMessage('Could not process the edit. Try again.');
      }
      return editedPath;
    } catch (e) {
      onErrorMessage('Error processing edit: $e');
      return null;
    } finally {
      _isSaving = false;
      update();
    }
  }

  @override
  void onClose() {
    editorController.dispose();
    super.onClose();
  }
}
