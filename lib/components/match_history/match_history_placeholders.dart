import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';

class MatchHistoryEmptyPlaceholder extends StatelessWidget {
  const MatchHistoryEmptyPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoTeamsPlaceholder extends StatelessWidget {
  const NoTeamsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No teams yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join or create a team to see your match history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppConstants.routes.addTeam),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Team'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.primaryColor),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
