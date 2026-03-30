import 'package:flutter/material.dart';
import '../../components/shared/custom_button.dart';
import '../../components/shared/custom_text_field.dart';
import '../../core/utils/validators.dart';
import '../../core/config/constants.dart';

class ForgotPasswordEmailStep extends StatelessWidget {
  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSendOtp;
  final VoidCallback onBackToLogin;
  final bool isLoading;

  const ForgotPasswordEmailStep({
    super.key,
    required this.emailController,
    required this.formKey,
    required this.onSendOtp,
    required this.onBackToLogin,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: formKey,
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
              controller: emailController,
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
              onPressed: onSendOtp,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),

            // Back to Login
            Center(
              child: TextButton(
                onPressed: onBackToLogin,
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
}
