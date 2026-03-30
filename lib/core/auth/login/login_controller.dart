import 'package:flutter_application_1/core/utils/exception_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../config/constants.dart';
import '../auth_state_controller.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();
  final AuthStateController _authStateController =
      Get.find<AuthStateController>();

  final RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> signIn() async {
    try {
      if (!loginFormKey.currentState!.validate()) return;

      _isLoading.value = true;

      final result = await _authService.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (result != null) {
        _authStateController.setUser(result);
        _clearControllers();
        Get.offAllNamed(AppConstants.routes.dashboard);
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
  }

  void goToSignup() {
    _clearControllers();
    Get.offNamed(AppConstants.routes.signup);
  }

  void goToForgotPassword() {
    Get.toNamed(AppConstants.routes.forgotPassword);
  }
}
