import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AppSnackbar {
  static void show({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration? duration,
    Widget? icon,
  }) {
    // Dismiss any existing snackbar first
    if (Get.isSnackbarOpen) {
      return;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor,
      colorText: textColor,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: icon,
      isDismissible: true,
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
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void error({required String title, required String message}) {
    show(
      title: title,
      message: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  static void info({required String title, required String message}) {
    show(
      title: title,
      message: message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }

  static void warning({required String title, required String message}) {
    show(
      title: title,
      message: message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
    );
  }

  static void comingSoon({required String feature}) {
    info(title: 'Coming Soon', message: '$feature will be available soon');
  }
}
