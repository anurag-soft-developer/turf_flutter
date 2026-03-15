import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../components/loading_overlay.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthController authController = Get.find();
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
              children: [_buildEmailStep(), _buildOtpStep()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryColor).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_outlined,
                  size: 40,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Enter your email address and we\'ll send you a 6-digit OTP to reset your password.',
              style: TextStyle(
                fontSize: 16,
                color: Color(AppColors.textSecondaryColor),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Email Field
            CustomTextField(
              controller: _emailController,
              labelText: 'Email Address',
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: Color(AppColors.textSecondaryColor),
              ),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 32),

            // Send OTP Button
            CustomButton(
              text: 'Send OTP',
              onPressed: _sendOtp,
              isLoading: authController.isLoading,
            ),
            const SizedBox(height: 24),

            // Back to Login
            Center(
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: Color(AppColors.primaryColor),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _resetFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryColor).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_outlined,
                  size: 40,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(AppColors.textSecondaryColor),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'We sent a 6-digit OTP to '),
                  TextSpan(
                    text: _emailController.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.primaryColor),
                    ),
                  ),
                  const TextSpan(
                    text: '. Enter the code to reset your password.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // OTP Field
            CustomTextField(
              controller: _otpController,
              labelText: '6-Digit OTP',
              hintText: 'Enter OTP',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              prefixIcon: const Icon(
                Icons.security,
                color: Color(AppColors.textSecondaryColor),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'OTP is required';
                }
                if (value.length != 6) {
                  return 'OTP must be 6 digits';
                }
                if (!RegExp(r'^\d+$').hasMatch(value)) {
                  return 'OTP must contain only numbers';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // New Password Field
            CustomTextField(
              controller: _newPasswordController,
              labelText: 'New Password',
              hintText: 'Enter new password',
              obscureText: true,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(AppColors.textSecondaryColor),
              ),
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 24),

            // Confirm Password Field
            CustomTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              hintText: 'Confirm new password',
              obscureText: true,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(AppColors.textSecondaryColor),
              ),
              validator: (value) => Validators.validateConfirmPassword(
                value,
                _newPasswordController.text,
              ),
            ),
            const SizedBox(height: 32),

            // Reset Password Button
            CustomButton(
              text: 'Reset Password',
              onPressed: _resetPassword,
              isLoading: authController.isLoading,
            ),
            const SizedBox(height: 24),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    'Change Email',
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: Color(AppColors.primaryColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
