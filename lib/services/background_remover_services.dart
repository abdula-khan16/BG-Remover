import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

class BackgroundRemoverService {
  // ========== CONSTANTS ==========
  static const int inputSize = 320;
  static const String modelAsset = 'assets/models/u2netp.onnx';

  // ========== PRIVATE VARIABLES ==========
  OrtSession? _session;
  List<String> _inputNames = [];
  List<String> _outputNames = [];
  bool _isLoaded = false;

  // ========== GETTERS ==========
  bool get isLoaded => _isLoaded;
  String get modelStatus => _isLoaded ? '✅ Model loaded' : '❌ Model not loaded';

  // ========== LOAD MODEL ==========
  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      final rawAsset = await rootBundle.load(modelAsset);
      final bytes = rawAsset.buffer.asUint8List();
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      _inputNames = _session!.inputNames;
      _outputNames = _session!.outputNames;
      _isLoaded = true;
      print('✅ Model loaded successfully');
      print('📥 Input names: $_inputNames');
      print('📤 Output names: $_outputNames');
    } catch (e) {
      _isLoaded = false;
      throw Exception('Failed to load model: $e');
    }
  }

  // ========== REMOVE BACKGROUND ==========
  Future<File> removeBackground(String imagePath) async {
    if (!_isLoaded) await loadModel();
    if (_session == null) throw Exception('Model not loaded');

    // 1. Read and decode image
    final origBytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(origBytes);
    if (original == null) {
      throw Exception('Could not decode image');
    }

    // 2. Preprocess image
    final inputData = _preprocessImage(original);

    // 3. Run inference
    final maskFlat = await _runInference(inputData);

    // 4. Create mask image
    final maskImage = _createMaskImage(maskFlat);

    // 5. Resize mask to original size
    final maskResized = img.copyResize(
      maskImage,
      width: original.width,
      height: original.height,
    );

    // 6. Apply mask to original image
    final output = _applyMask(original, maskResized);

    // 7. Save result
    return await _saveResult(output);
  }

  // ========== PREPROCESS IMAGE ==========
  Float32List _preprocessImage(img.Image image) {
    // Resize to 320x320
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // ImageNet normalization values
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    // NCHW layout: [1, 3, 320, 320]
    final inputData = Float32List(1 * 3 * inputSize * inputSize);
    int idx = 0;

    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          double v;
          if (c == 0) {
            v = pixel.r / 255.0;
          } else if (c == 1) {
            v = pixel.g / 255.0;
          } else {
            v = pixel.b / 255.0;
          }
          inputData[idx++] = (v - mean[c]) / std[c];
        }
      }
    }

    return inputData;
  }

  // ========== RUN INFERENCE ==========
  Future<Float32List> _runInference(Float32List inputData) async {
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      inputData,
      [1, 3, inputSize, inputSize],
    );

    final inputName = _inputNames.isNotEmpty ? _inputNames.first : 'input.1';
    final inputs = {inputName: inputTensor};
    final runOptions = OrtRunOptions();
    final outputs = await _session!.runAsync(runOptions, inputs);

    inputTensor.release();
    runOptions.release();

    if (outputs == null || outputs.isEmpty || outputs.first == null) {
      throw Exception('Model returned no output');
    }

    // First output is the fused saliency/alpha mask, shape [1,1,320,320]
    final maskTensor = outputs.first!;
    final maskValue = maskTensor.value;
    final maskFlat = _flattenToFloat32List(maskValue);

    for (final o in outputs) {
      o?.release();
    }

    return maskFlat;
  }

  // ========== CREATE MASK IMAGE ==========
  img.Image _createMaskImage(Float32List maskFlat) {
    final maskImage = img.Image(width: inputSize, height: inputSize);

    // Normalize mask values
    double minV = maskFlat.reduce((a, b) => a < b ? a : b);
    double maxV = maskFlat.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final raw = maskFlat[y * inputSize + x];
        final norm = ((raw - minV) / range).clamp(0.0, 1.0);
        final g = (norm * 255).round();
        maskImage.setPixelRgba(x, y, g, g, g, 255);
      }
    }

    return maskImage;
  }

  // ========== APPLY MASK ==========
  img.Image _applyMask(img.Image original, img.Image mask) {
    final output = img.Image(
      width: original.width,
      height: original.height,
      numChannels: 4,
    );

    for (int y = 0; y < original.height; y++) {
      for (int x = 0; x < original.width; x++) {
        final p = original.getPixel(x, y);
        final alpha = mask.getPixel(x, y).r; // 0-255
        output.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
      }
    }

    return output;
  }

  // ========== SAVE RESULT ==========
  Future<File> _saveResult(img.Image image) async {
    final pngBytes = img.encodePng(image);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = File('${tempDir.path}/bg_removed_$timestamp.png');
    await outputFile.writeAsBytes(pngBytes);
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

  // ========== DISPOSE ==========
  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
    _isLoaded = false;
    _session = null;
  }
}