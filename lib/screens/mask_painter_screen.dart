import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/operation_type.dart';
import '../utils/constants.dart';
import 'processing_screen.dart';
import 'dart:async';

class MaskPainterScreen extends StatefulWidget {
  final String imagePath;

  const MaskPainterScreen({super.key, required this.imagePath});

  @override
  State<MaskPainterScreen> createState() => _MaskPainterScreenState();
}

class _MaskPainterScreenState extends State<MaskPainterScreen> {
  ui.Image? _image;
  final List<List<Offset>> _paths = [];
  List<Offset> _currentPath = [];
  bool _isProcessing = false;
  double _strokeWidth = 25.0;
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      final box = _paintKey.currentContext!.findRenderObject() as RenderBox;
      final point = box.globalToLocal(details.globalPosition);
      _currentPath = [point];
      _paths.add(_currentPath);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final box = _paintKey.currentContext!.findRenderObject() as RenderBox;
      final point = box.globalToLocal(details.globalPosition);
      _currentPath.add(point);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Current path is already in _paths
  }

  void _clear() {
    setState(() {
      _paths.clear();
      _currentPath.clear();
    });
  }

  Future<void> _generateMaskAndProcess() async {
    if (_image == null || _paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw over the watermark first!')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create a recorder to render the mask
      final recorder = ui.PictureRecorder();
      // The canvas size must exactly match the original image size
      final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble()));

      // 1. Draw solid black background
      final bgPaint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble()), bgPaint);

      // 2. Draw white strokes where the user painted
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = _strokeWidth; // We must scale strokeWidth if drawing surface was scaled

      // Wait, we need to map the screen coordinates back to the original image coordinates!
      // To do this simply, we will calculate the scale factor in the build method.
      // To do this simply, we will calculate the scale factor using the painting area's size.
      
      final RenderBox box = _paintKey.currentContext!.findRenderObject() as RenderBox;
      final Size screenSize = box.size;
      
      // Calculate how the image was fitted (BoxFit.contain)
      double scaleX = screenSize.width / _image!.width;
      double scaleY = screenSize.height / _image!.height;
      double scale = scaleX < scaleY ? scaleX : scaleY;
      
      double offsetX = (screenSize.width - _image!.width * scale) / 2;
      double offsetY = (screenSize.height - _image!.height * scale) / 2;

      for (final path in _paths) {
        if (path.isEmpty) continue;
        final uiPath = Path();
        
        // Map screen point to image point
        Offset mapPoint(Offset p) {
          return Offset((p.dx - offsetX) / scale, (p.dy - offsetY) / scale);
        }

        uiPath.moveTo(mapPoint(path.first).dx, mapPoint(path.first).dy);
        for (int i = 1; i < path.length; i++) {
          final p = mapPoint(path[i]);
          uiPath.lineTo(p.dx, p.dy);
        }
        
        // Scale stroke width relative to image
        strokePaint.strokeWidth = _strokeWidth / scale;
        canvas.drawPath(uiPath, strokePaint);
      }

      final picture = recorder.endRecording();
      final maskImage = await picture.toImage(_image!.width, _image!.height);
      final byteData = await maskImage.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final maskPath = '${tempDir.path}/mask_$timestamp.png';
      
      await File(maskPath).writeAsBytes(buffer);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(
              imagePath: widget.imagePath,
              operationType: OperationType.removeWatermark,
              maskFile: File(maskPath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating mask: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Highlight Watermark'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              if (_paths.isNotEmpty) {
                setState(() {
                  _paths.removeLast();
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clear,
          ),
        ],
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Builder(
                      builder: (context) {
                        return CustomPaint(
                          key: _paintKey,
                          painter: _MaskPainter(
                            image: _image!,
                            paths: _paths,
                            strokeWidth: _strokeWidth,
                          ),
                          size: Size.infinite,
                        );
                      }
                    ),
                  ),
                ),
                Container(
                  color: Colors.grey.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.brush, color: Colors.white70, size: 20),
                            Expanded(
                              child: Slider(
                                value: _strokeWidth,
                                min: 5.0,
                                max: 50.0,
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  setState(() {
                                    _strokeWidth = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _generateMaskAndProcess,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('Done', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final ui.Image image;
  final List<List<Offset>> paths;
  final double strokeWidth;

  _MaskPainter({
    required this.image,
    required this.paths,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate how the image fits into the screen (BoxFit.contain)
    double scaleX = size.width / image.width;
    double scaleY = size.height / image.height;
    double scale = scaleX < scaleY ? scaleX : scaleY;

    double offsetX = (size.width - image.width * scale) / 2;
    double offsetY = (size.height - image.height * scale) / 2;

    // Draw the original image
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();

    // Draw a dark overlay so user can see their mask clearly
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withOpacity(0.4));

    // Draw the red brush strokes
    final paint = Paint()
      ..color = Colors.redAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;

    for (final path in paths) {
      if (path.isEmpty) continue;
      final uiPath = Path();
      uiPath.moveTo(path.first.dx, path.first.dy);
      for (int i = 1; i < path.length; i++) {
        uiPath.lineTo(path[i].dx, path[i].dy);
      }
      canvas.drawPath(uiPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) {
    return true; // Simple repaint always
  }
}
