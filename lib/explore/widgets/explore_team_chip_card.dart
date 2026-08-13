import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../core/config/constants.dart';
import '../../team/model/team_model.dart';

class ExploreTeamChipCard extends StatelessWidget {
  const ExploreTeamChipCard({super.key, required this.team});

  final TeamModel team;

  static const double width = 132;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final id = team.id;
            if (id != null && id.isNotEmpty) {
              Get.toNamed(
                AppConstants.routes.teamProfile,
                arguments: {'teamId': id},
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(AppColors.dividerColor).withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TeamLogo(url: team.logo, size: 40, teamId: team.id),
                const SizedBox(height: 6),
                Text(
                  team.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  team.sportType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                if (team.teamOpenForMatch) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.successColor)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(AppColors.successColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
