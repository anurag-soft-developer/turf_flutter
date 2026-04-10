import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/custom_button.dart';
import '../components/shared/custom_text_field.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/config/constants.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/validators.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final AuthStateController _auth = Get.find<AuthStateController>();

  bool _busy = false;

  Future<void> _startChange({required bool enable}) async {
    setState(() => _busy = true);
    final sent = await _auth.sendTwoFactorOtp();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!sent) return;

    final success = await Get.dialog<bool>(
      _TwoFactorOtpDialog(
        enable: enable,
        onConfirm: (otp) => _auth.updateTwoFactor(enabled: enable, otp: otp),
      ),
      barrierDismissible: false,
    );

    if (success == true && mounted) {
      AppSnackbar.success(
        title: 'Updated',
        message: enable
            ? 'Two-factor authentication is now on.'
            : 'Two-factor authentication is now off.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        final enabled = _auth.user?.twoFactorEnabled == true;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 1,
                color: const Color(AppColors.surfaceColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            enabled
                                ? Icons.verified_user
                                : Icons.security_outlined,
                            color: const Color(AppColors.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            enabled ? 'Enabled' : 'Disabled',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(AppColors.textColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'When 2FA is on, you need an email code to sign in and whenever you change your password.',
                        style: TextStyle(
                          color: Color(AppColors.textSecondaryColor),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: enabled
                    ? 'Turn off two-factor authentication'
                    : 'Turn on two-factor authentication',
                onPressed: _busy ? null : () => _startChange(enable: !enabled),
                isLoading: _busy,
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// OTP field controller is owned here and disposed in [State.dispose] after the
/// route is removed, so focus / text input can finish teardown safely.
class _TwoFactorOtpDialog extends StatefulWidget {
  const _TwoFactorOtpDialog({
    required this.enable,
    required this.onConfirm,
  });

  final bool enable;
  final Future<bool> Function(String otp) onConfirm;

  @override
  State<_TwoFactorOtpDialog> createState() => _TwoFactorOtpDialogState();
}

class _TwoFactorOtpDialogState extends State<_TwoFactorOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await widget.onConfirm(_otpController.text.trim());
    if (!ok || !mounted) return;
    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(AppColors.backgroundColor),
      title: Text(
        widget.enable ? 'Enable 2FA' : 'Disable 2FA',
        style: const TextStyle(color: Color(AppColors.primaryColor)),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.enable
                  ? 'Enter the code sent to your email to turn on two-factor authentication.'
                  : 'Enter the code sent to your email to turn off two-factor authentication.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _otpController,
              labelText: 'Verification code',
              keyboardType: TextInputType.number,
              maxLength: AppConstants.otp.length,
              validator: Validators.validateOtp,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(AppColors.errorColor)),
          ),
        ),
        TextButton(
          onPressed: _onConfirm,
          child: const Text(
            'Confirm',
            style: TextStyle(color: Color(AppColors.primaryColor)),
          ),
        ),
      ],
    );
  }
}
