import 'package:flutter/material.dart';
import '../../components/shared/custom_button.dart';
import '../../components/shared/custom_text_field.dart';
import '../../components/shared/otp_input_field.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

class ForgotPasswordOtpStep extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onResetPassword;
  final VoidCallback onChangeEmail;
  final VoidCallback onResendOtp;
  final bool isLoading;

  const ForgotPasswordOtpStep({
    super.key,
    required this.email,
    required this.otpController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.onResetPassword,
    required this.onChangeEmail,
    required this.onResendOtp,
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
                    text: email,
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
            OtpInputField(controller: otpController),
            const SizedBox(height: 24),

            // New Password Field
            CustomTextField(
              controller: newPasswordController,
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
              controller: confirmPasswordController,
              labelText: 'Confirm Password',
              hintText: 'Confirm new password',
              obscureText: true,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(AppColors.textSecondaryColor),
              ),
              validator: (value) => Validators.validateConfirmPassword(
                value,
                newPasswordController.text,
              ),
            ),
            const SizedBox(height: 32),

            // Reset Password Button
            CustomButton(
              text: 'Reset Password',
              onPressed: onResetPassword,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onChangeEmail,
                  child: const Text(
                    'Change Email',
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onResendOtp,
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
}
