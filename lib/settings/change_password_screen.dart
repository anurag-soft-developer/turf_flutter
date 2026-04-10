import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/custom_button.dart';
import '../components/shared/custom_text_field.dart';
import '../components/shared/password_text_field.dart';
import '../components/shared/loading_overlay.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/config/constants.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/validators.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthStateController _auth = Get.find<AuthStateController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _submitting = false;
  bool _sendingOtp = false;
  bool _initialOtpSent = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_needsOtpForVerification && mounted) {
        _sendOtp(isInitial: true);
      }
    });
  }

  bool get _hasPassword => _auth.user?.isPasswordExists == true;

  bool get _twoFactorOn => _auth.user?.twoFactorEnabled == true;

  /// OAuth / no local password, or 2FA (always verify with OTP for password change).
  bool get _needsOtpForVerification => !_hasPassword || _twoFactorOn;

  Future<void> _sendOtp({bool isInitial = false}) async {
    if (_sendingOtp) return;
    setState(() => _sendingOtp = true);
    final ok = await _auth.sendChangePasswordOtp();
    if (!mounted) return;
    setState(() => _sendingOtp = false);
    if (ok) {
      _initialOtpSent = true;
      if (!isInitial && mounted) {
        AppSnackbar.success(
          title: 'Code sent',
          message: 'Check your email for the verification code.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final ok = await _auth.changePassword(
      newPassword: _newPasswordController.text.trim(),
      currentPassword:
          _hasPassword ? _currentPasswordController.text.trim() : null,
      otp: _needsOtpForVerification ? _otpController.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      await _auth.refreshUserProfile();
      if (mounted) {
        Get.back();
        AppSnackbar.success(
          title: 'Success',
          message: 'Your password was updated.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(
        () => LoadingOverlay(
          isLoading: _submitting,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_needsOtpForVerification) ...[
                    Text(
                      _twoFactorOn && _hasPassword
                          ? 'Two-factor authentication is on. Enter the code we email you, plus your current password.'
                          : _twoFactorOn
                              ? 'Two-factor authentication is on. Enter the code we email you.'
                              : 'You signed in without a password. Enter the code we email you to set a new password.',
                      style: const TextStyle(
                        color: Color(AppColors.textSecondaryColor),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _otpController,
                      labelText: 'Verification code',
                      hintText: '${AppConstants.otp.length}-digit code',
                      keyboardType: TextInputType.number,
                      maxLength: AppConstants.otp.length,
                      validator: Validators.validateOtp,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _sendingOtp ? null : () => _sendOtp(),
                        child: _sendingOtp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _initialOtpSent
                                    ? 'Resend code'
                                    : 'Send code',
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_hasPassword) ...[
                    CustomTextField(
                      controller: _currentPasswordController,
                      labelText: 'Current password',
                      obscureText: true,
                      validator: (v) =>
                          Validators.validateRequired(v, 'Current password'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  PasswordTextField(
                    controller: _newPasswordController,
                    labelText: 'New password',
                    hintText: 'Enter a new password',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm new password',
                    obscureText: true,
                    validator: (v) => Validators.validateConfirmPassword(
                      v,
                      _newPasswordController.text,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Update password',
                    onPressed: _submit,
                    isLoading: _submitting,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
