import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../core/utils/validators.dart';

/// New-password field with the same rules as the backend: shows each failed rule on its own line.
class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final AutovalidateMode autovalidateMode;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  String? _validator(String? value) {
    final errors = Validators.passwordRequirementErrors(value);
    if (errors.isEmpty) return null;
    return errors.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.labelText!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.textColor),
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          enabled: widget.enabled,
          autovalidateMode: widget.autovalidateMode,
          validator: _validator,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(AppColors.textSecondaryColor),
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            filled: true,
            fillColor: const Color(AppColors.surfaceColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(AppColors.primaryColor),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(AppColors.errorColor)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(AppColors.errorColor),
                width: 2,
              ),
            ),
            errorMaxLines: 10,
            errorStyle: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(AppColors.errorColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintStyle: const TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 14,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(AppColors.textColor),
          ),
        ),
      ],
    );
  }
}
