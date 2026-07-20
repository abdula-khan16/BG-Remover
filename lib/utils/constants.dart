import 'package:flutter/material.dart';

// ============================================
// APP COLORS
// ============================================
class AppColors {
  // Primary Purple
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primarySurface = Color(0xFFF5F3FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1F2937);
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFFF3F4F6);
  static const Color grayDark = Color(0xFF4B5563);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

// ============================================
// APP STRINGS
// ============================================
class AppStrings {
  // App Info
  static const String appName = 'BG Eraser';
  static const String appTagline = 'Remove Background & Watermark in Seconds';
  static const String appSubtitle = 'AI-powered. 100% free. Works offline.';
  static const String version = '1.0.0';

  // Home Screen
  static const String homeTitle = 'BG Eraser';
  static const String uploadHint = 'Supports JPG, PNG, WEBP';
  static const String camera = 'Camera';
  static const String gallery = 'Gallery';

  // Features
  static const String featureFast = '2~3 Sec';
  static const String featurePrivate = 'Private';
  static const String featureEdit = 'Edit BG';

  // Recent Edits
  static const String recentEdits = 'Recent Edits';
  static const String viewAll = 'View All';
  static const String noHistory = 'No edits yet';
  static const String noHistorySub = 'Remove your first background!';

  // Pro Feature
  static const String proTitle = 'Try Pro Features';
  static const String proSubtitle = 'HD export, batch removal & more';
  static const String tryFree = 'Try Free →';

  // Buttons
  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String done = 'Done';
  static const String cancel = 'Cancel';
  static const String apply = 'Apply';
  static const String save = 'Save';
  static const String share = 'Share';
  static const String delete = 'Delete';
  static const String clear = 'Clear';
  static const String retry = 'Retry';

  // Crop Screen
  static const String cropTitle = 'Adjust Subject';
  static const String cropHint = 'Drag to adjust crop area';
  static const String applyCrop = 'Apply Crop';

  // Processing Screen
  static const String processingTitle = 'Removing Background...';
  static const String loadingModel = 'Loading AI Model...';
  static const String analyzing = 'Analyzing subject...';
  static const String removing = 'Removing background...';
  static const String almostDone = 'Almost done...';
  static const String processingHint = 'This happens on your device. No data uploaded.';

  // Editor Screen
  static const String editorTitle = 'Edit Background';
  static const String tabColors = 'COLORS';
  static const String tabGradients = 'GRADIENTS';
  static const String tabImages = 'IMAGES';
  static const String blurBg = 'Blur BG';
  static const String shadow = 'Shadow';
  static const String border = 'Border';
  static const String reset = 'Reset';

  // Export Screen
  static const String exportTitle = 'Export';
  static const String fileSize = 'File Size';
  static const String dimensions = 'Dimensions';
  static const String format = 'Format';
  static const String saveToGallery = 'Save to Gallery';
  static const String shareImage = 'Share';
  static const String saveToCloud = 'Save to Cloud';
  static const String setWallpaper = 'Set as Wallpaper';
  static const String newImage = 'New Image';

  // Errors
  static const String errorTitle = 'Something went wrong';
  static const String errorPermission = 'Permission denied';
  static const String errorCamera = 'Camera not available';
  static const String errorGallery = 'Gallery not available';
  static const String errorModel = 'Failed to load AI model';
  static const String errorProcessing = 'Failed to process image';
  static const String errorSaving = 'Failed to save image';
  static const String errorSharing = 'Failed to share image';
}