import 'package:flutter/material.dart';
import '../../controllers/auth/auth_state_controller.dart';
import '../../config/constants.dart';

class WelcomeCard extends StatelessWidget {
  final AuthStateController authController;

  const WelcomeCard({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(AppColors.primaryColor),
              Color(AppColors.secondaryColor),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              authController.user?.fullName ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Have a great day ahead!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
