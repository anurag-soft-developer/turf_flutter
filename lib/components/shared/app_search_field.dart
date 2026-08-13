import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

/// Shared search field used on list screens (Matches, My Teams, etc.).
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onCleared,
    this.textInputAction = TextInputAction.search,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCleared;
  final TextInputAction textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return TextField(
          controller: controller,
          autofocus: autofocus,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: const TextStyle(
            color: Color(AppColors.textColor),
            fontSize: 15,
          ),
          cursorColor: const Color(AppColors.primaryColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 15,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(AppColors.textSecondaryColor),
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                      onCleared?.call();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(
                  AppColors.dividerColor,
                ).withValues(alpha: 0.6),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(
                  AppColors.dividerColor,
                ).withValues(alpha: 0.6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(AppColors.primaryColor),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        );
      },
    );
  }
}
