import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user/user_model.dart';
import '../config/constants.dart';

class AuthStateController extends GetxController {
  static AuthStateController get instance => Get.find();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isLoggedIn = false.obs;
  final RxBool _updatingNotificationSettings = false.obs;

  UserModel? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _isLoggedIn.value;
  /// Use `.value` inside [Obx] so toggles rebuild while PATCH runs.
  RxBool get notificationSettingsUpdating => _updatingNotificationSettings;

  @override
  void onInit() {
    super.onInit();
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    _isLoading.value = true;

    final storedUser = await _authService.getStoredUser();
    if (storedUser != null) {
      _user.value = storedUser;
      _isLoggedIn.value = true;
      if (Get.currentRoute == '/') {
        Get.offAllNamed(AppConstants.routes.dashboard);
      }
    }

    _isLoading.value = false;
  }

  void setUser(UserModel user) {
    _user.value = user;
    _isLoggedIn.value = true;
  }

  Future<void> signOut() async {
    _isLoading.value = true;

    await _authService.signOut();

    _user.value = null;
    _isLoggedIn.value = false;

    Get.offAllNamed(AppConstants.routes.login);

    _isLoading.value = false;
  }

  Future<void> updateUserProfile({
    String? fullName,
    String? bio,
    String? phone,
    String? avatar,
  }) async {
    _isLoading.value = true;

    final result = await _authService.updateUserProfile(
      fullName: fullName,
      bio: bio,
      phone: phone,
      avatar: avatar,
    );

    if (result != null) {
      _user.value = result;
    }

    _isLoading.value = false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading.value = true;
    await _authService.sendPasswordResetEmail(email);
    _isLoading.value = false;
  }

  Future<bool> sendOtpForPasswordReset(String email) async {
    _isLoading.value = true;
    final success = await _authService.sendOtpForPasswordReset(email);
    _isLoading.value = false;
    return success;
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading.value = true;
    final success = await _authService.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    _isLoading.value = false;
    return success;
  }

  Future<void> signInWithGoogle() async {
    _isLoading.value = true;

    final result = await _authService.signInWithGoogle();

    if (result != null) {
      setUser(result);
      Get.offAllNamed(AppConstants.routes.dashboard);
    }

    _isLoading.value = false;
  }

  Future<bool> changePassword({
    required String newPassword,
    String? currentPassword,
    String? otp,
  }) async {
    return _authService.changePassword(
      newPassword: newPassword,
      currentPassword: currentPassword,
      otp: otp,
    );
  }

  Future<bool> sendChangePasswordOtp() async {
    return _authService.sendChangePasswordOtp();
  }

  Future<bool> sendTwoFactorOtp() async {
    return _authService.sendTwoFactorOtp();
  }

  Future<bool> updateTwoFactor({
    required bool enabled,
    required String otp,
  }) async {
    final updated = await _authService.updateTwoFactor(
      enabled: enabled,
      otp: otp,
    );
    if (updated != null) {
      _user.value = updated;
      return true;
    }
    return false;
  }

  Future<void> refreshUserProfile() async {
    final profile = await _authService.getCurrentUserProfile();
    if (profile != null) {
      _user.value = profile;
    }
  }

  Future<bool> updateNotificationSettings({
    bool? emailNotificationsEnabled,
    bool? smsNotificationsEnabled,
  }) async {
    _updatingNotificationSettings.value = true;
    try {
      final updated = await _userService.updateNotificationSettings(
        emailNotificationsEnabled: emailNotificationsEnabled,
        smsNotificationsEnabled: smsNotificationsEnabled,
      );
      if (updated != null) {
        _user.value = updated;
        await _authService.persistUser(updated);
        return true;
      }
      return false;
    } finally {
      _updatingNotificationSettings.value = false;
    }
  }
}
