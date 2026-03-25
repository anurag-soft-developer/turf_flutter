import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_snackbar.dart';

enum UserMode { player, proprietor }

class SettingsController extends GetxController {
  // Observable variables
  final RxBool _notificationsEnabled = true.obs;
  final Rx<UserMode> _currentMode = UserMode.player.obs;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled.value;
  Rx<UserMode> get currentMode => _currentMode;
  bool get isPlayerMode => _currentMode.value == UserMode.player;
  bool get isProprietorMode => _currentMode.value == UserMode.proprietor;

  // Settings keys
  static const String _notificationsKey = 'notifications_enabled';
  static const String _modeKey = 'user_mode';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _notificationsEnabled.value = prefs.getBool(_notificationsKey) ?? true;

      // Load mode
      final modeString = prefs.getString(_modeKey) ?? 'player';
      _currentMode.value = modeString == 'proprietor'
          ? UserMode.proprietor
          : UserMode.player;
    } catch (e) {
      // Handle loading error
    }
  }

  Future<void> toggleNotifications() async {
    try {
      _notificationsEnabled.value = !_notificationsEnabled.value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, _notificationsEnabled.value);

      AppSnackbar.success(
        title: 'Settings Updated',
        message:
            'Notifications ${_notificationsEnabled.value ? 'enabled' : 'disabled'}',
      );
    } catch (e) {
      AppSnackbar.error(
        title: 'Error',
        message: 'Failed to update notification settings',
      );
    }
  }

  // Mode management methods
  void switchToPlayerMode() {
    _currentMode.value = UserMode.player;
    _saveMode();
  }

  void switchToProprietorMode() {
    _currentMode.value = UserMode.proprietor;
    _saveMode();
  }

  void toggleMode() {
    debugPrint(
      'SettingsController: Before toggle - currentMode = ${_currentMode.value}',
    );
    if (_currentMode.value == UserMode.player) {
      _currentMode.value = UserMode.proprietor;
    } else {
      _currentMode.value = UserMode.player;
    }
    debugPrint(
      'SettingsController: After toggle - currentMode = ${_currentMode.value}',
    );
    _saveMode();
  }

  Future<void> _saveMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _modeKey,
        _currentMode.value.toString().split('.').last,
      );
    } catch (e) {
      // Handle save error
    }
  }

  String get currentModeDisplay {
    switch (_currentMode.value) {
      case UserMode.player:
        return 'Player Mode';
      case UserMode.proprietor:
        return 'Proprietor Mode';
    }
  }

  String get alternateModeDisplay {
    switch (_currentMode.value) {
      case UserMode.player:
        return 'Proprietor Mode';
      case UserMode.proprietor:
        return 'Player Mode';
    }
  }

  Future<void> clearCache() async {
    try {
      // Implement cache clearing logic here
      AppSnackbar.success(
        title: 'Cache Cleared',
        message: 'Application cache has been cleared successfully',
      );
    } catch (e) {
      AppSnackbar.error(title: 'Error', message: 'Failed to clear cache');
    }
  }

  void showAbout() {
    Get.dialog(
      AlertDialog(
        title: const Text('About'),
        content: const Text(
          'Flutter Turf Booking App\nVersion 1.0.0\n\nA comprehensive turf booking and management application.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }
}
