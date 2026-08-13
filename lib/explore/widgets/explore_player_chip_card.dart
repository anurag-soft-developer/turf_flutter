import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/rankings/player_avatar.dart';
import '../../core/config/constants.dart';
import '../../core/models/user/user_model.dart';

class ExplorePlayerChipCard extends StatelessWidget {
  const ExplorePlayerChipCard({super.key, required this.player});

  final UserModel player;

  static const double width = 108;

  @override
  Widget build(BuildContext context) {
    final name = player.displayName;
    final userId = player.id;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: userId == null || userId.isEmpty
              ? null
              : () => Get.toNamed(
                    AppConstants.routes.teamMemberProfile,
                    arguments: {'userId': userId},
                  ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(AppColors.dividerColor).withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayerAvatar(
                  url: player.avatar ?? '',
                  name: name,
                  size: 48,
                  userId: null,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
