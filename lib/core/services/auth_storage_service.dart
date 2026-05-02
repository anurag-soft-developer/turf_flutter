import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/user/user_model.dart';

class AuthStorageService {
  static final AuthStorageService _instance = AuthStorageService._internal();
  factory AuthStorageService() => _instance;
  AuthStorageService._internal();

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.storageKeys.accessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.storageKeys.refreshToken);
  }

  Future<void> setAccessToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.storageKeys.accessToken, token);
  }

  Future<void> setRefreshToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.storageKeys.refreshToken, token);
  }

  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await prefs.remove(AppConstants.storageKeys.accessToken);
    await prefs.remove(AppConstants.storageKeys.refreshToken);
  }

  Future<void> storeAuthData(AuthResponse authResponse) async {
    await setAccessToken(authResponse.accessToken);
    await setRefreshToken(authResponse.refreshToken);
    await saveUser(authResponse.user);
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await _prefs;
    await prefs.setString(
      AppConstants.storageKeys.userData,
      json.encode(user.toJson()),
    );
    await prefs.setBool(AppConstants.storageKeys.isLoggedIn, true);
  }

  Future<UserModel?> getUserFromPreferences() async {
    final prefs = await _prefs;
    final userJson = prefs.getString(AppConstants.storageKeys.userData);
    if (userJson == null || userJson.isEmpty) {
      return null;
    }

    final userMap = json.decode(userJson) as Map<String, dynamic>;
    return UserModel.fromJson(userMap);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.storageKeys.isLoggedIn) ?? false;
  }

  Future<void> clearAuthData() async {
    final prefs = await _prefs;
    await prefs.remove(AppConstants.storageKeys.userData);
    await prefs.setBool(AppConstants.storageKeys.isLoggedIn, false);
    await clearTokens();
  }
}
