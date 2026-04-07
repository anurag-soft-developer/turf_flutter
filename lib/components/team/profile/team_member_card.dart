import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../team/members/model/team_member_model.dart';
import '../../../team/utils/team_ui.dart';

class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({super.key, required this.member});

  final TeamMemberModel member;

  @override
  Widget build(BuildContext context) {
    final helper = member.userHelper;
    final avatar = helper.getAvatar();
    final role = leadershipRoleLabel(member.leadershipRole);
    final hasRole = role.isNotEmpty;

    return InkWell(
      onTap: () => Get.toNamed(
        AppConstants.routes.teamMemberProfile,
        arguments: {'user': member.user},
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: hasRole
              ? Border.all(
                  color: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.25),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.1),
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  child: avatar == null || avatar.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Color(AppColors.primaryColor),
                          size: 26,
                        )
                      : null,
                ),
                if (member.jerseyNumber != null)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${member.jerseyNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              member.nickname ?? helper.getDisplayName(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.textColor),
              ),
            ),
            if (hasRole)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              )
            else if (member.playingPosition != null &&
                member.playingPosition!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  member.playingPosition!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
