import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/constants.dart';
import '../components/shared/custom_button.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(
                      AppColors.errorColor,
                    ).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    size: 60,
                    color: Color(AppColors.errorColor),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(AppColors.textColor),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                const Text(
                  'You don\'t have permission to access this resource. Please contact your administrator if you believe this is an error.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(AppColors.textSecondaryColor),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Action Buttons
                Column(
                  children: [
                    // Go Back Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Go Back',
                        onPressed: () {
                          final navigator = Get.key.currentState;
                          if (navigator != null && navigator.canPop()) {
                            Get.back();
                          } else {
                            Get.offAllNamed(AppConstants.routes.dashboard);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Home Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.offAllNamed(AppConstants.routes.dashboard);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(AppColors.primaryColor),
                          side: const BorderSide(
                            color: Color(AppColors.primaryColor),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Go to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
