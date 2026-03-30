import 'package:flutter/material.dart';
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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
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
                  emailController: _emailController,
                  formKey: _emailFormKey,
                  onSendOtp: _sendOtp,
                  onBackToLogin: () => Get.back(),
                  isLoading: authController.isLoading,
                ),
                ForgotPasswordOtpStep(
                  email: _emailController.text,
                  otpController: _otpController,
                  newPasswordController: _newPasswordController,
                  confirmPasswordController: _confirmPasswordController,
                  formKey: _resetFormKey,
                  onResetPassword: _resetPassword,
                  onChangeEmail: _onChangeEmail,
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

  void _onChangeEmail() {
    setState(() {
      _currentStep = 0;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final success = await authController.sendOtpForPasswordReset(
      _emailController.text.trim(),
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

  void _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    final success = await authController.resetPasswordWithOtp(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );

    if (success) {
      Get.back();
    }
  }

  void _resendOtp() async {
    await authController.sendOtpForPasswordReset(_emailController.text.trim());
  }
}
