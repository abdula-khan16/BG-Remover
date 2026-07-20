import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../viewmodels/preview_viewmodel.dart';
import '../models/operation_type.dart';
import 'processing_screen.dart';
import 'mask_painter_screen.dart';

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
  final PreviewViewModel _viewModel = Get.put(PreviewViewModel());
  late final isDarkMode = Theme.of(context).brightness == Brightness.dark;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GetBuilder<PreviewViewModel>(
        builder: (controller) {
          return Column(
            children: [
              // ========== IMAGE EDITOR (crop / rotate / scale) ==========
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                          cropAspectRatio: null,
                          cropRectPadding: const EdgeInsets.all(20),
                          hitTestSize: 20,
                          controller: controller.editorController,
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
                    _buildToolButton(
                      icon: Icons.rotate_left,
                      tooltip: 'Rotate left',
                      onPressed: () => controller.rotate(false),
                    ),
                    _buildToolButton(
                      icon: Icons.rotate_right,
                      tooltip: 'Rotate right',
                      onPressed: () => controller.rotate(true),
                    ),
                    _buildToolButton(
                      icon: Icons.flip,
                      tooltip: 'Flip',
                      onPressed: controller.flip,
                    ),
                    _buildToolButton(
                      icon: Icons.restore,
                      tooltip: 'Reset',
                      onPressed: controller.reset,
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
                    color: isDarkMode ? AppColors.white : Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ========== PROCESS BUTTONS ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isSaving
                            ? null
                            : () async {
                                final editedPath = await controller.processImage(
                                  onErrorMessage: (msg) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                  },
                                );
                                if (editedPath != null && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProcessingScreen(
                                        imagePath: editedPath,
                                        operationType: OperationType.removeBackground,
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_fix_high),
                                  SizedBox(width: 12),
                                  Text('Remove Background', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isSaving
                            ? null
                            : () async {
                                final editedPath = await controller.processImage(
                                  onErrorMessage: (msg) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                  },
                                );
                                if (editedPath != null && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MaskPainterScreen(
                                        imagePath: editedPath,
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.water_drop),
                                  SizedBox(width: 12),
                                  Text('Remove Watermark', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ========== CANCEL BUTTON ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: controller.isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: isDarkMode ? AppColors.white : Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.redAccent),),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

Widget _buildToolButton({
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.black),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  );
}