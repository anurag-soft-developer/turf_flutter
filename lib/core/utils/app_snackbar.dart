import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AppSnackbar {
  static const _iconSize = 18.0;

  static void show({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration? duration,
    Widget? icon,
  }) {
    if (Get.isSnackbarOpen) {
      return;
    }

    final foreground = textColor ?? Colors.white;

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: backgroundColor,
      colorText: foreground,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 10,
      icon: icon,
      shouldIconPulse: false,
      isDismissible: true,
      titleText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.15,
            ),
          ),
          Text(
            message,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ],
      ),
      messageText: const SizedBox.shrink(),
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
    );
  }

  static void success({required String title, required String message}) {
    show(
      title: title,
      message: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white, size: _iconSize),
    );
  }

  static void error({required String title, required String message}) {
    show(
      title: title,
      message: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white, size: _iconSize),
    );
  }

  static void info({required String title, required String message}) {
    show(
      title: title,
      message: message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white, size: _iconSize),
    );
  }

  static void warning({required String title, required String message}) {
    show(
      title: title,
      message: message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white, size: _iconSize),
    );
  }

  static void comingSoon({required String feature}) {
    info(title: 'Coming Soon', message: '$feature will be available soon');
  }
}
