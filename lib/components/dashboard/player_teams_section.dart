import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';

class PlayerTeamsSection extends StatelessWidget {
  const PlayerTeamsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teams',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.groups, color: Color(AppColors.primaryColor)),
                title: const Text('My team'),
                subtitle: const Text('Your roster, or create / join'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(AppConstants.routes.myTeam),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.leaderboard_outlined,
                  color: Color(AppColors.primaryColor),
                ),
                title: const Text('Team rankings'),
                subtitle: const Text('Browse public teams (order is provisional)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(AppConstants.routes.teamsRanking),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
