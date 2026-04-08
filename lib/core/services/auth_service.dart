import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user/user_model.dart';
import '../config/constants.dart';
import '../config/api_constants.dart';
import '../utils/exception_handler.dart';
import 'api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

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

    if (response == null) {
      return null;
    }

    final authResponse = AuthResponse.fromJson(response);

    await _storeAuthData(authResponse);

    ExceptionHandler.showSuccessToast(AppConstants.successMessages.signup);
    return authResponse.user;
  }

  Future<LoginResult?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final loginRequest = LoginRequest(email: email, password: password);

    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.auth.login,
      data: loginRequest.toJson(),
    );

    if (response == null) {
      return null;
    }

    final requiresOtp = response['requiresOtp'] == true;
    if (requiresOtp) {
      return LoginResult.challenge(
        LoginOtpChallengeResponse.fromJson(response),
      );
    }

    final authResponse = AuthResponse.fromJson(response);
    await _storeAuthData(authResponse);
    ExceptionHandler.showSuccessToast(AppConstants.successMessages.login);
    return LoginResult.authenticated(authResponse.user);
  }

  Future<UserModel?> verifyLoginOtp({
    required String email,
    required String otp,
  }) async {
    final request = VerifyLoginOtpRequest(email: email, otp: otp);
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.auth.verifyLoginOtp,
      data: request.toJson(),
    );
    if (response == null) return null;
    final authResponse = AuthResponse.fromJson(response);
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

      if (response == null) {
        return null;
      }

      final authResponse = AuthResponse.fromJson(response);

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
    await _apiService.post(ApiConstants.auth.logout);
    await clearAuthData();
    ExceptionHandler.showSuccessToast(AppConstants.successMessages.logout);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _apiService.post(
      ApiConstants.auth.forgotPassword,
      data: {'email': email},
    );
    ExceptionHandler.showSuccessToast('Password reset email sent');
  }

  Future<bool> sendOtpForPasswordReset(String email) async {
    final response = await _apiService.post(
      ApiConstants.auth.forgotPassword,
      data: {'email': email},
    );

    return response != null;
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _apiService.post(
      ApiConstants.auth.resetPassword,
      data: {'email': email, 'otp': otp, 'password': newPassword},
    );

    return response != null;
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

    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.user.updateProfile,
      data: updateData,
    );

    if (response == null) {
      return null;
    }
    final updatedUser = UserModel.fromJson(response);
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
    await _apiService.patch(
      ApiConstants.auth.changePassword,
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );

    ExceptionHandler.showSuccessToast('Password changed successfully');
    return true;
  }

  Future<bool> sendChangePasswordOtp() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.auth.sendChangePasswordOtp,
    );
    return response != null;
  }

  Future<bool> sendTwoFactorOtp() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.auth.sendTwoFactorOtp,
    );
    return response != null;
  }

  Future<UserModel?> updateTwoFactor({
    required bool enabled,
    required String otp,
  }) async {
    final request = UpdateTwoFactorRequest(enabled: enabled, otp: otp);
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.auth.updateTwoFactor,
      data: request.toJson(),
    );
    if (response == null) return null;
    final updatedUser = UserModel.fromJson(response);
    await _saveUserToPreferences(updatedUser);
    return updatedUser;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.user.profile,
    );

    if (response != null) {
      final user = UserModel.fromJson(response);
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
