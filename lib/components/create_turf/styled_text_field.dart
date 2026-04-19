import 'package:flutter/material.dart';

class StyledTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;
  final String? helperText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool autoExpand;

  const StyledTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
    this.helperText,
    this.keyboardType,
    this.validator,
    this.onTap,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autoExpand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: true,
          fillColor: Colors
              .transparent, // Transparent since container has white background
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: const TextStyle(color: Colors.grey),
          helperText: helperText,
          helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onTap: onTap,
        onFieldSubmitted: onFieldSubmitted,
        readOnly: readOnly,
        maxLines: autoExpand ? null : maxLines,
        minLines: autoExpand ? (minLines ?? 1) : null,
        enabled: enabled,
      ),
    );
  }
}

// Predefined styled text field for common use cases
class TurfFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final String? prefixText;
  final String? helperText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool autoExpand;

  const TurfFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
    this.helperText,
    this.keyboardType,
    this.validator,
    this.onTap,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.autoExpand = false,
  });

  @override
  Widget build(BuildContext context) {
    return StyledTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: Colors.grey.shade600)
          : null,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey.shade600)
          : null,
      prefixText: prefixText,
      helperText: helperText,
      keyboardType: keyboardType,
      validator: validator,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      autoExpand: autoExpand,
    );
  }
}
