import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final AuthService _authService = AuthService();

  // Observable variables
  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isLoggedIn = false.obs;

  // Getters
  UserModel? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _isLoggedIn.value;

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _initializeAuthService();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  // Initialize auth service
  Future<void> _initializeAuthService() async {
    _isLoading.value = true;

    await _authService.initialize();

    if (_authService.isLoggedIn && _authService.currentUser != null) {
      _user.value = _authService.currentUser;
      _isLoggedIn.value = true;
      // Only navigate to dashboard if we're on the initial route
      if (Get.currentRoute == '/') {
        Get.offAllNamed(AppConstants.routes.dashboard);
      }
    }

    _isLoading.value = false;
  }

  // Sign up with email and password
  Future<void> signUp() async {
    if (!signupFormKey.currentState!.validate()) return;

    _isLoading.value = true;

    final result = await _authService.signUpWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      fullName: fullNameController.text.trim(),
      phone: phoneController.text.trim().isNotEmpty
          ? phoneController.text.trim()
          : null,
    );

    if (result != null) {
      _user.value = result;
      _isLoggedIn.value = true;
      _clearControllers();
      Get.offAllNamed(AppConstants.routes.dashboard);
    }

    _isLoading.value = false;
  }

  // Sign in with email and password
  Future<void> signIn() async {
    if (!loginFormKey.currentState!.validate()) return;

    _isLoading.value = true;

    final result = await _authService.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (result != null) {
      _user.value = result;
      _isLoggedIn.value = true;
      _clearControllers();
      Get.offAllNamed(AppConstants.routes.dashboard);
    }

    _isLoading.value = false;
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    _isLoading.value = true;

    final result = await _authService.signInWithGoogle();

    if (result != null) {
      _user.value = result;
      _isLoggedIn.value = true;
      Get.offAllNamed(AppConstants.routes.dashboard);
    }

    _isLoading.value = false;
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading.value = true;

    await _authService.signOut();

    _user.value = null;
    _isLoggedIn.value = false;
    _clearControllers();

    Get.offAllNamed(AppConstants.routes.login);

    _isLoading.value = false;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading.value = true;
    await _authService.sendPasswordResetEmail(email);
    _isLoading.value = false;
  }

  // Send OTP for password reset
  Future<bool> sendOtpForPasswordReset(String email) async {
    _isLoading.value = true;
    final success = await _authService.sendOtpForPasswordReset(email);
    _isLoading.value = false;
    return success;
  }

  // Reset password with OTP
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

  // Navigate to forgot password screen
  void goToForgotPassword() {
    Get.toNamed(AppConstants.routes.forgotPassword);
  }

  // Update user profile
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

  // Navigate to login screen
  void goToLogin() {
    _clearControllers();
    Get.offNamed(AppConstants.routes.login);
  }

  // Navigate to signup screen
  void goToSignup() {
    _clearControllers();
    Get.offNamed(AppConstants.routes.signup);
  }

  // Clear form controllers
  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    fullNameController.clear();
    phoneController.clear();
  }
}
