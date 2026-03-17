import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/api_constants.dart';
import '../utils/exception_handler.dart';
import 'api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> initialize() async {
    _apiService.initialize();
  }

  Future<UserModel?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.storageKeys.userData);
      final isLoggedIn =
          prefs.getBool(AppConstants.storageKeys.isLoggedIn) ?? false;
      final token = await _apiService.getStoredToken();

      if (userJson != null && isLoggedIn && token != null) {
        final userMap = json.decode(userJson);
        return UserModel.fromJson(userMap);
      } else {
        await clearAuthData();
        return null;
      }
    } catch (e) {
      await clearAuthData();
      return null;
    }
  }

  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final registerRequest = RegisterRequest(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.auth.register,
      data: registerRequest.toJson(),
    );

    if (response?.data == null) {
      ExceptionHandler.showErrorToast(AppConstants.errorMessages.unknown);
      return null;
    }

    final authResponse = AuthResponse.fromJson(response!.data!);

    await _storeAuthData(authResponse);

    ExceptionHandler.showSuccessToast(AppConstants.successMessages.signup);
    return authResponse.user;
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final loginRequest = LoginRequest(email: email, password: password);

    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.auth.login,
      data: loginRequest.toJson(),
    );

    if (response?.data == null) {
      ExceptionHandler.showErrorToast('Failed to login.');
      return null;
    }

    final authResponse = AuthResponse.fromJson(response!.data!);

    await _storeAuthData(authResponse);

    ExceptionHandler.showSuccessToast(AppConstants.successMessages.login);
    return authResponse.user;
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(serverClientId: EnvConfig.googleClientId);

      final GoogleSignInAccount user = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication auth = user.authentication;

      final response = await _apiService.post(
        '/auth/google/mobile',
        data: {'idToken': auth.idToken},
      );

      if (response?.data == null) {
        ExceptionHandler.showErrorToast('Failed to login.');
        return null;
      }

      final authResponse = AuthResponse.fromJson(response!.data!);

      await _storeAuthData(authResponse);

      ExceptionHandler.showSuccessToast('Google Sign-In successful');
      return authResponse.user;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      ExceptionHandler.showErrorToast('Google Sign In failed');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _apiService.post(ApiConstants.auth.logout);
    } finally {
      await clearAuthData();
      ExceptionHandler.showSuccessToast(AppConstants.successMessages.logout);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _apiService.post(
      ApiConstants.auth.forgotPassword,
      data: {'email': email},
    );
    ExceptionHandler.showSuccessToast('Password reset email sent');
  }

  Future<bool> sendOtpForPasswordReset(String email) async {
    try {
      final response = await _apiService.post(
        ApiConstants.auth.forgotPassword,
        data: {'email': email},
      );

      if (response?.statusCode == 200) {
        ExceptionHandler.showSuccessToast(AppConstants.successMessages.otpSent);
        return true;
      }
      return false;
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to send OTP');
      return false;
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.auth.resetPassword,
        data: {'email': email, 'otp': otp, 'password': newPassword},
      );

      if (response?.statusCode == 200) {
        ExceptionHandler.showSuccessToast(
          AppConstants.successMessages.passwordReset,
        );
        return true;
      }
      return false;
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to reset password');
      return false;
    }
  }

  Future<UserModel?> updateUserProfile({
    String? fullName,
    String? bio,
    String? phone,
    String? avatar,
  }) async {
    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['fullName'] = fullName;
    if (bio != null) updateData['bio'] = bio;
    if (phone != null) updateData['phone'] = phone;
    if (avatar != null) updateData['avatar'] = avatar;

    final response = await _apiService.put<Map<String, dynamic>>(
      ApiConstants.user.updateProfile,
      data: updateData,
    );

    if (response?.data == null) {
      ExceptionHandler.showErrorToast('Failed to update profile');
      return null;
    }
    final updatedUser = UserModel.fromJson(response!.data!);
    await _saveUserToPreferences(updatedUser);

    ExceptionHandler.showSuccessToast(
      AppConstants.successMessages.profileUpdate,
    );
    return updatedUser;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.put(
        ApiConstants.user.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      ExceptionHandler.showSuccessToast('Password changed successfully');
      return true;
    } catch (e) {
      if (e is! Exception) {
        ExceptionHandler.showErrorToast('Failed to change password');
      }
      return false;
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.user.profile,
    );

    if (response != null && response.data != null) {
      final user = UserModel.fromJson(response.data!);
      await _saveUserToPreferences(user);
      return user;
    }
    return null;
  }

  // Store authentication data
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    await _apiService.storeToken(authResponse.accessToken);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', authResponse.refreshToken);

    await _saveUserToPreferences(authResponse.user);
  }

  // Save user to preferences
  Future<void> _saveUserToPreferences(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.storageKeys.userData,
        json.encode(user.toJson()),
      );
      await prefs.setBool(AppConstants.storageKeys.isLoggedIn, true);
    } catch (e) {
      // Handle preference save error
    }
  }

  // Clear all authentication data
  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.storageKeys.userData);
      await prefs.remove('refresh_token');
      await prefs.setBool(AppConstants.storageKeys.isLoggedIn, false);

      await _apiService.removeToken();
    } catch (e) {
      // Handle clear error
    }
  }

  // Get user from preferences
  Future<UserModel?> getUserFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.storageKeys.userData);

      if (userJson != null) {
        final userMap = json.decode(userJson);
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
