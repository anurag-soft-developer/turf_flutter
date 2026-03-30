import 'package:flutter/material.dart';
import '../../core/config/constants.dart';

class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final String labelText;
  final String hintText;

  const OtpInputField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.labelText = '6-Digit OTP',
    this.hintText = 'Enter OTP',
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.security,
          color: Color(AppColors.textSecondaryColor),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(AppColors.primaryColor),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        counterText: '',
      ),
      validator:
          validator ??
          (value) {
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
      onChanged: onChanged != null ? (value) => onChanged!() : null,
    );
  }
}
