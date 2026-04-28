import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../core/utils/app_snackbar.dart';
import '../core/models/location_model.dart';

enum UserMode { player, proprietor }

class SettingsController extends GetxController {
  // Observable variables
  final RxBool _notificationsEnabled = true.obs;
  final Rx<UserMode> _currentMode = UserMode.player.obs;
  final Rxn<LocationModel> _selectedCityLocation = Rxn<LocationModel>();
  final RxBool _isDetectingCityLocation = false.obs;

  // Controllers (shared across screens)
  final TextEditingController cityController = TextEditingController();

  // Getters
  bool get notificationsEnabled => _notificationsEnabled.value;
  Rx<UserMode> get currentMode => _currentMode;
  bool get isPlayerMode => _currentMode.value == UserMode.player;
  bool get isProprietorMode => _currentMode.value == UserMode.proprietor;
  Rxn<LocationModel> get selectedCityLocation => _selectedCityLocation;
  RxBool get isDetectingCityLocation => _isDetectingCityLocation;

  String get selectedCityLabel => _selectedCityLocation.value?.address ?? '';

  // Settings keys
  static const String _notificationsKey = 'notifications_enabled';
  static const String _modeKey = 'user_mode';
  static const String _cityLocationKey = 'selected_city_location';

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

      // Load persisted city location (if any)
      final raw = prefs.getString(_cityLocationKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
          final address = (jsonMap['address'] as String?) ?? '';
          final lat = (jsonMap['lat'] as num?)?.toDouble();
          final lng = (jsonMap['lng'] as num?)?.toDouble();

          if (address.isNotEmpty && lat != null && lng != null) {
            _selectedCityLocation.value = LocationModel(
              address: address,
              coordinates: GeoPointModel.fromLngLat(
                longitude: lng,
                latitude: lat,
              ),
            );
            cityController.text = address;
          }
        } catch (_) {
          // ignore parse errors
        }
      }
    } catch (e) {
      // Handle loading error
    }
  }

  Future<void> setCityLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    cityController.text = address;
    _selectedCityLocation.value = LocationModel(
      address: address,
      coordinates: GeoPointModel.fromLngLat(
        longitude: longitude,
        latitude: latitude,
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cityLocationKey,
        jsonEncode({'address': address, 'lat': latitude, 'lng': longitude}),
      );
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<void> clearCityLocation() async {
    cityController.clear();
    _selectedCityLocation.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cityLocationKey);
    } catch (_) {
      // ignore
    }
  }

  Future<void> detectCurrentCityLocation({
    bool requestPermission = true,
  }) async {
    if (_isDetectingCityLocation.value) return;
    _isDetectingCityLocation.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      String label = '${position.latitude}, ${position.longitude}';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String?>[
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((e) => e?.trim().isNotEmpty == true).toList();
          if (parts.isNotEmpty) label = parts.join(', ');
        }
      } catch (_) {}

      await setCityLocation(
        address: label,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // ignore
    } finally {
      _isDetectingCityLocation.value = false;
    }
  }

  @override
  void onClose() {
    cityController.dispose();
    super.onClose();
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
