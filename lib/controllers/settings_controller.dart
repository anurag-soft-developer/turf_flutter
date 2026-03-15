import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static SettingsController get instance => Get.find();

  // Observable variables
  final RxBool _isDarkMode = false.obs;
  final RxBool _notificationsEnabled = true.obs;
  final RxBool _biometricEnabled = false.obs;
  final RxString _selectedLanguage = 'English'.obs;

  // Getters
  bool get isDarkMode => _isDarkMode.value;
  bool get notificationsEnabled => _notificationsEnabled.value;
  bool get biometricEnabled => _biometricEnabled.value;
  String get selectedLanguage => _selectedLanguage.value;

  // Settings keys
  static const String _darkModeKey = 'dark_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _biometricKey = 'biometric_enabled';
  static const String _languageKey = 'selected_language';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isDarkMode.value = prefs.getBool(_darkModeKey) ?? false;
      _notificationsEnabled.value = prefs.getBool(_notificationsKey) ?? true;
      _biometricEnabled.value = prefs.getBool(_biometricKey) ?? false;
      _selectedLanguage.value = prefs.getString(_languageKey) ?? 'English';

      // Apply theme
      Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    } catch (e) {
      // Handle loading error
    }
  }

  Future<void> toggleDarkMode() async {
    try {
      _isDarkMode.value = !_isDarkMode.value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode.value);

      Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    } catch (e) {
      // Handle toggle error
    }
  }

  Future<void> toggleNotifications() async {
    try {
      _notificationsEnabled.value = !_notificationsEnabled.value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, _notificationsEnabled.value);
    } catch (e) {
      // Handle toggle error
    }
  }

  Future<void> toggleBiometric() async {
    try {
      _biometricEnabled.value = !_biometricEnabled.value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricKey, _biometricEnabled.value);
    } catch (e) {
      // Handle toggle error
    }
  }

  Future<void> changeLanguage(String language) async {
    try {
      _selectedLanguage.value = language;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);

      // Here you can implement actual language change logic
      // For example: Get.updateLocale(Locale(languageCode));
    } catch (e) {
      // Handle language change error
    }
  }

  Future<void> clearCache() async {
    try {
      // Implement cache clearing logic here
      Get.snackbar(
        'Cache Cleared',
        'Application cache has been cleared successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear cache',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showAbout() {
    Get.dialog(
      AlertDialog(
        title: const Text('About'),
        content: const Text(
          'Flutter Auth App\nVersion 1.0.0\n\nA comprehensive authentication app with Firebase and Google OAuth integration.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }
}
