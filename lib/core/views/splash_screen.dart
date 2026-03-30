import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/auth_state_controller.dart';
import '../config/constants.dart';

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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.security,
                size: 60,
                color: Color(AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Tagline
            Text(
              'Secure Authentication Made Simple',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 50),

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
              ? AppConstants.routes.dashboard
              : AppConstants.routes.login,
        );
      });

      // Show SplashScreen while navigating
      return const SplashScreen();
    });
  }
}
