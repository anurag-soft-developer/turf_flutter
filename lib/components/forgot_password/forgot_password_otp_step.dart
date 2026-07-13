import 'package:flutter/material.dart';
import '../../components/shared/custom_button.dart';
import '../../components/shared/custom_text_field.dart';
import '../../components/shared/password_text_field.dart';
import '../../components/shared/otp_input_field.dart';
import '../../core/utils/validators.dart';
import '../../core/config/constants.dart';

class ForgotPasswordOtpStep extends StatelessWidget {
  final String destination;
  final TextEditingController otpController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onResetPassword;
  final VoidCallback onChangeIdentifier;
  final VoidCallback onResendOtp;
  final bool isLoading;

  const ForgotPasswordOtpStep({
    super.key,
    required this.destination,
    required this.otpController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.onResetPassword,
    required this.onChangeIdentifier,
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

            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),

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
                    text: destination,
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

            OtpInputField(controller: otpController),
            const SizedBox(height: 24),

            PasswordTextField(
              controller: newPasswordController,
              labelText: 'New Password',
              hintText: 'Enter new password',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 24),

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

            CustomButton(
              text: 'Reset Password',
              onPressed: onResetPassword,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onChangeIdentifier,
                  child: const Text(
                    'Change email or phone',
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
