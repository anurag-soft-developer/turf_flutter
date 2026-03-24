import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../utils/app_snackbar.dart';

class TurfManagementSection extends StatelessWidget {
  const TurfManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Turf Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildManagementCard(
                title: 'Add New Turf',
                subtitle: 'Create a new turf listing',
                icon: Icons.add_business,
                color: const Color(AppColors.primaryColor),
                onTap: () {
                  AppSnackbar.comingSoon(feature: 'Add New Turf');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildManagementCard(
                title: 'My Turfs',
                subtitle: 'Manage existing turfs',
                icon: Icons.grass,
                color: Colors.green,
                onTap: () {
                  AppSnackbar.comingSoon(feature: 'My Turfs management');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
