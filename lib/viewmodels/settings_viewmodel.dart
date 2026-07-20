import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsViewModel extends GetxController {
  bool _isDarkMode = Get.isDarkMode;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    update();
  }
}
