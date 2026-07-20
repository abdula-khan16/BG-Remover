import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../viewmodels/result_viewmodel.dart';

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
  final ResultViewModel _viewModel = Get.put(ResultViewModel());

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ResultViewModel>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Result'),
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
                      value: controller.getFileSize(widget.resultImage),
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
                        onPressed: controller.isSaving
                            ? null
                            : () => controller.saveToGallery(
                                  widget.resultImage,
                                  onMessage: _showSnackBar,
                                ),
                        icon: controller.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(controller.isSaving ? 'Saving...' : 'Save'),
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
                        onPressed: controller.isSharing
                            ? null
                            : () => controller.shareImage(
                                  widget.resultImage,
                                  onMessage: _showSnackBar,
                                ),
                        icon: controller.isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share),
                        label: Text(controller.isSharing ? 'Sharing...' : 'Share'),
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
      },
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