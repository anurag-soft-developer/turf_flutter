import 'package:flutter_application_1/core/utils/exception_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../config/constants.dart';
import '../../routes/app_routes.dart';
import '../auth_state_controller.dart';

class SignupController extends GetxController {
  final AuthService _authService = AuthService();
  final AuthStateController _authStateController =
      Get.find<AuthStateController>();

  final RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Form key
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> signUp() async {
    try {
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
        _authStateController.setUser(result);
        _clearControllers();
        Get.offAllNamed(AppRoutes.mainRoute);
      }

      _isLoading.value = false;
    } catch (e) {
      ExceptionHandler.handleException(e);
      _isLoading.value = false;
    }
  }

  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    fullNameController.clear();
    phoneController.clear();
  }

  void goToLogin() {
    _clearControllers();
    Get.offNamed(AppConstants.routes.login);
  }
}
