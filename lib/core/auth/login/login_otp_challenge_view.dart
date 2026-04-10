import 'package:flutter/material.dart';

import '../../../components/shared/custom_button.dart';
import '../../../components/shared/otp_input_field.dart';
import '../../config/constants.dart';
import '../../utils/validators.dart';

class LoginOtpChallengeView extends StatelessWidget {
  const LoginOtpChallengeView({
    super.key,
    required this.email,
    required this.formKey,
    required this.otpController,
    required this.onVerify,
    required this.onBack,
    required this.isLoading,
  });

  final String email;
  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final VoidCallback onVerify;
  final VoidCallback onBack;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Enter verification code',
              style: TextStyle(
                fontSize: 32,
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
                  const TextSpan(
                    text: 'Enter the verification code we sent to ',
                  ),
                  TextSpan(
                    text: email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.primaryColor),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            OtpInputField(
              controller: otpController,
              validator: Validators.validateOtp,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Verify & sign in',
              onPressed: onVerify,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: isLoading ? null : onBack,
              child: const Text(
                'Back to sign in',
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
