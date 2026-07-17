import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/background_remover_services.dart';
import '../utils/image_storage_helper.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;

  const ProcessingScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final BackgroundRemoverService _remover = BackgroundRemoverService();
  double _progress = 0.0;
  String _status = 'Loading AI Model...';
  bool _isProcessing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  // ========== AUTO SYNC LOGIC ==========
  Future<void> _autoSyncToCloud(File file) async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      // Check if user is logged in (not guest)
      final prefs = await SharedPreferences.getInstance();
      final bool isGuest = prefs.getBool('isGuest') ?? false;

      if (session != null && !isGuest) {
        // Check internet connectivity
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          final fileName = file.path.split('/').last;
          final userId = session.user.id;
          
          setState(() => _status = 'Syncing to cloud...');
          
          await supabase.storage.from('edits').upload(
            '$userId/$fileName',
            file,
            fileOptions: const FileOptions(upsert: true),
          );
          debugPrint('✅ Auto-synced to Supabase');
        }
      }
    } catch (e) {
      debugPrint('❌ Auto-sync failed: $e');
      // We don't block the user if sync fails, just continue to result screen
    }
  }

  // ========== PROCESS IMAGE ==========
  Future<void> _processImage() async {
    try {
      // Step 1: Load Model (0-30%)
      setState(() {
        _progress = 0.1;
        _status = 'Loading AI Model...';
      });

      await _remover.loadModel();

      setState(() {
        _progress = 0.3;
        _status = 'Analyzing image...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Process Image (30-80%)
      setState(() {
        _progress = 0.5;
        _status = 'Removing background...';
      });

      final resultFile = await _remover.removeBackground(widget.imagePath);

      setState(() {
        _progress = 0.8;
        _status = 'Saving locally...';
      });

      // ✅ SAVE TO PERMANENT LOCAL STORAGE
      final bytes = await resultFile.readAsBytes();
      final permanentPath = await ImageStorageHelper.saveImage(bytes);
      final permanentFile = File(permanentPath);

      // ✅ ATTEMPT AUTO-SYNC IF LOGGED IN & ONLINE
      await _autoSyncToCloud(permanentFile);

      setState(() {
        _progress = 1.0;
        _status = 'Done! ✨';
        _isProcessing = false;
      });

      // ✅ Navigate to Result Screen
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              resultImage: permanentFile,
              originalImage: File(widget.imagePath),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
        _status = '❌ Failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _remover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C3AED),
      appBar: AppBar(
        title: const Text('Processing...'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ========== PROGRESS ==========
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_progress < 1.0)
                        const SizedBox(height: 4),
                      if (_progress < 1.0)
                        Text(
                          _status,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ========== STATUS ==========
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'This happens on your device.\nPrivacy first.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ========== RETRY ==========
              if (_error != null)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _progress = 0.0;
                      _status = 'Retrying...';
                      _isProcessing = true;
                    });
                    _processImage();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7C3AED),
                  ),
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
