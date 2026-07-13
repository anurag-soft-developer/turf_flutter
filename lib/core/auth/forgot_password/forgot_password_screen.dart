import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/utils/app_snackbar.dart';
import 'package:flutter_application_1/core/utils/phone_util.dart';
import 'package:get/get.dart';
import '../auth_state_controller.dart';
import '../../../components/shared/loading_overlay.dart';
import '../../../components/forgot_password/forgot_password_email_step.dart';
import '../../../components/forgot_password/forgot_password_otp_step.dart';
import '../../config/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthStateController authController = Get.find();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _identifierFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();

  AuthIdentifier? _resolvedIdentifier;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String get _destinationDisplay {
    final id = _resolvedIdentifier;
    if (id == null) return _identifierController.text.trim();
    return id.email ?? id.phone ?? _identifierController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(AppColors.textColor)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _currentStep == 0 ? 'Reset Password' : 'Enter OTP',
          style: const TextStyle(
            color: Color(AppColors.textColor),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(
        () => LoadingOverlay(
          isLoading: authController.isLoading,
          child: SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ForgotPasswordEmailStep(
                  identifierController: _identifierController,
                  formKey: _identifierFormKey,
                  onSendOtp: _sendOtp,
                  onBackToLogin: () => Get.back(),
                  isLoading: authController.isLoading,
                ),
                ForgotPasswordOtpStep(
                  destination: _destinationDisplay,
                  otpController: _otpController,
                  newPasswordController: _newPasswordController,
                  confirmPasswordController: _confirmPasswordController,
                  formKey: _resetFormKey,
                  onResetPassword: _resetPassword,
                  onChangeIdentifier: _onChangeIdentifier,
                  onResendOtp: _resendOtp,
                  isLoading: authController.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onChangeIdentifier() {
    setState(() {
      _currentStep = 0;
      _resolvedIdentifier = null;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _sendOtp() async {
    if (!_identifierFormKey.currentState!.validate()) return;

    final identifier = resolveIdentifier(_identifierController.text);
    _resolvedIdentifier = identifier;

    final success = await authController.sendOtpForPasswordReset(
      email: identifier.email,
      phone: identifier.phone,
    );

    if (success) {
      setState(() {
        _currentStep = 1;
      });
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    final identifier =
        _resolvedIdentifier ?? resolveIdentifier(_identifierController.text);

    final success = await authController.resetPasswordWithOtp(
      email: identifier.email,
      phone: identifier.phone,
      otp: _otpController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );

    if (success) {
      Get.back();
      AppSnackbar.success(
        title: 'Success',
        message: 'Your password has been reset successfully.',
      );
    }
  }

  Future<void> _resendOtp() async {
    final identifier =
        _resolvedIdentifier ?? resolveIdentifier(_identifierController.text);
    await authController.sendOtpForPasswordReset(
      email: identifier.email,
      phone: identifier.phone,
    );
  }
}
