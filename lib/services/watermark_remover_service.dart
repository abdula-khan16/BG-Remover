import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

class WatermarkRemoverService {
  static const int inputSize = 512; // LaMa usually works well with 512x512
  static const String modelAsset = 'assets/models/lama_fp32.onnx';

  OrtSession? _session;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      final rawAsset = await rootBundle.load(modelAsset);
      final bytes = rawAsset.buffer.asUint8List();
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      throw Exception('Failed to load LaMa model: $e');
    }
  }

  Future<File> removeWatermark(String imagePath, String maskPath) async {
    if (!_isLoaded) await loadModel();
    if (_session == null) throw Exception('Model not loaded');

    // 1. Read and decode original image and mask
    final origBytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(origBytes);
    if (original == null) throw Exception('Could not decode image');

    final maskBytes = await File(maskPath).readAsBytes();
    final maskImage = img.decodeImage(maskBytes);
    if (maskImage == null) throw Exception('Could not decode mask');

    // 2. Resize both to inputSize (512x512)
    final resizedImg = img.copyResize(original, width: inputSize, height: inputSize);
    final resizedMask = img.copyResize(maskImage, width: inputSize, height: inputSize);

    // 3. Prepare Image Tensor [1, 3, 512, 512]
    final imageTensor = Float32List(1 * 3 * inputSize * inputSize);
    int imgIdx = 0;
    // NCHW
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resizedImg.getPixel(x, y);
          double v;
          if (c == 0) v = pixel.r / 255.0;
          else if (c == 1) v = pixel.g / 255.0;
          else v = pixel.b / 255.0;
          imageTensor[imgIdx++] = v;
        }
      }
    }

    // 4. Prepare Mask Tensor [1, 1, 512, 512]
    final maskTensor = Float32List(1 * 1 * inputSize * inputSize);
    int maskIdx = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resizedMask.getPixel(x, y);
        // Assuming mask is black/white where white is the watermark
        // Or if the mask we created is red brush on black, we can check R channel
        // In MaskPainterScreen we drew white on black.
        double v = pixel.r / 255.0; 
        maskTensor[maskIdx++] = v > 0.1 ? 1.0 : 0.0;
      }
    }

    // 5. Run inference
    final inputs = {
      _session!.inputNames[0]: OrtValueTensor.createTensorWithDataList(
        imageTensor,
        [1, 3, inputSize, inputSize],
      ),
      _session!.inputNames[1]: OrtValueTensor.createTensorWithDataList(
        maskTensor,
        [1, 1, inputSize, inputSize],
      ),
    };

    final runOptions = OrtRunOptions();
    final outputs = await _session!.runAsync(runOptions, inputs);
    
    if (outputs == null || outputs.isEmpty || outputs.first == null) {
      throw Exception('Model returned no output');
    }

    final outputTensor = outputs.first!;
    final outputValue = outputTensor.value;
    final outFlat = _flattenToFloat32List(outputValue);

    // 6. Post-process the output tensor
    // LaMa outputs [1, 3, 512, 512] in NCHW format
    final outImg = img.Image(width: inputSize, height: inputSize);
    
    // Check output scale (0-1 vs 0-255)
    double maxVal = 0.0;
    for (int i = 0; i < outFlat.length; i += 50) {
      if (outFlat[i] > maxVal) maxVal = outFlat[i];
    }
    final double scaleMultiplier = maxVal <= 1.1 ? 255.0 : 1.0;
    
    // outFlat contains 3 * 512 * 512 elements
    final channelSize = inputSize * inputSize;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixelIdx = y * inputSize + x;
        final rRaw = outFlat[pixelIdx];
        final gRaw = outFlat[pixelIdx + channelSize];
        final bRaw = outFlat[pixelIdx + 2 * channelSize];

        num r = (rRaw * scaleMultiplier).clamp(0.0, 255.0).round();
        num g = (gRaw * scaleMultiplier).clamp(0.0, 255.0).round();
        num b = (bRaw * scaleMultiplier).clamp(0.0, 255.0).round();
        
        outImg.setPixelRgb(x, y, r, g, b);
      }
    }

    // 7. Resize back to original dimensions
    final finalImage = img.copyResize(outImg, width: original.width, height: original.height);
    
    // Cleanup ORT values
    inputs.values.forEach((v) => v.release());
    outputs.forEach((v) => v?.release());
    runOptions.release();

    // 8. Save and return
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/lama_result_$timestamp.png';
    
    final outputBytes = img.encodePng(finalImage);
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(outputBytes);
    
    return outputFile;
  }
  
  // ========== FLATTEN TENSOR ==========
  Float32List _flattenToFloat32List(dynamic value) {
    final List<double> out = [];
    void walk(dynamic v) {
      if (v is List) {
        for (final e in v) {
          walk(e);
        }
      } else if (v is num) {
        out.add(v.toDouble());
      }
    }
    walk(value);
    return Float32List.fromList(out);
  }
  
  void dispose() {
    _session?.release();
  }
}
