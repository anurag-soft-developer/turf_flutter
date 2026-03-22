import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subdued section title
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        const SizedBox(height: 12),

        // Compact grid with smaller, less prominent cards
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _buildQuickActionCard(
              icon: Icons.person,
              title: 'Profile',
              onTap: () => Get.toNamed(AppConstants.routes.profile),
            ),
            _buildQuickActionCard(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => Get.toNamed(AppConstants.routes.settings),
            ),
            _buildQuickActionCard(
              icon: Icons.security,
              title: 'Security',
              onTap: () {
                Get.snackbar(
                  'Coming Soon',
                  'Security settings will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            _buildQuickActionCard(
              icon: Icons.history,
              title: 'Bookings',
              onTap: () {
                Get.snackbar(
                  'Coming Soon',
                  'Booking history will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            _buildQuickActionCard(
              icon: Icons.help,
              title: 'Help',
              onTap: () {
                Get.snackbar(
                  'Help',
                  'Contact us at support@example.com',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.grey[600]),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
