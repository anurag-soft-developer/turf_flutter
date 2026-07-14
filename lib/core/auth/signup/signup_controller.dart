import 'package:flutter_application_1/core/utils/exception_handler.dart';
import 'package:flutter_application_1/components/shared/confirm_phone_dialog.dart';
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

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();

  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    super.onClose();
  }

  Future<void> signUp() async {
    try {
      if (!signupFormKey.currentState!.validate()) return;

      final context = Get.context;
      if (context == null) return;

      final identifier = await resolveAuthIdentifier(
        context,
        identifierController.text,
      );
      if (identifier == null) return;

      if (identifier.phone != null) {
        identifierController.text = identifier.phone!;
      }

      _isLoading.value = true;

      final result = await _authService.signUpWithEmailAndPassword(
        email: identifier.email,
        phone: identifier.phone,
        password: passwordController.text.trim(),
        fullName: fullNameController.text.trim(),
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
    identifierController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    fullNameController.clear();
  }

  void goToLogin() {
    _clearControllers();
    Get.offNamed(AppConstants.routes.login);
  }
}
