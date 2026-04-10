import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _version = '1.0.0';

  String get _appName {
    final n = AppConstants.appName.trim();
    return n.isNotEmpty ? n : 'Turf Booking';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        AppColors.primaryColor,
                      ).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  size: 48,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _appName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Version $_version',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(AppColors.surfaceColor),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(AppColors.dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About this app',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(AppColors.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_appName brings players and turf owners together. '
                    'Discover venues, book slots in a few taps, manage your '
                    'reservations, and organise teams — all in one place.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Whether you are looking for a pitch for the weekend or '
                    'running multiple grounds, the app is built to keep '
                    'scheduling simple and communication clear.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: const Color(
                        AppColors.textColor,
                      ).withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Legal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              color: const Color(AppColors.surfaceColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _legalTile(
                    title: 'Terms & Conditions',
                    subtitle: 'Rules for using the service',
                    icon: Icons.description_outlined,
                    onTap: () =>
                        Get.toNamed(AppConstants.routes.termsOfService),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(AppColors.dividerColor),
                  ),
                  _legalTile(
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    icon: Icons.policy_outlined,
                    onTap: () => Get.toNamed(AppConstants.routes.privacyPolicy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _legalTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(AppColors.textColor),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Color(AppColors.textSecondaryColor),
        ),
      ),
      leading: Icon(icon, color: const Color(AppColors.primaryColor)),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(AppColors.textSecondaryColor),
      ),
      onTap: onTap,
    );
  }
}
