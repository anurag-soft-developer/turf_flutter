import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/auth_state_controller.dart';
import '../config/constants.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.primaryColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logos/splash_logo.png',
              width: 220,
              fit: BoxFit.contain,
            ),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends GetWidget<AuthStateController> {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const SplashScreen();
      }

      // Navigate once after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(
          controller.isLoggedIn
              ? AppRoutes.mainRoute
              : AppConstants.routes.login,
        );
      });

      // Show SplashScreen while navigating
      return const SplashScreen();
    });
  }
}
