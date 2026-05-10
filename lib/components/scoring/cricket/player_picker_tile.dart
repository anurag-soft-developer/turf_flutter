import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../team/members/model/team_member_model.dart';

/// Tile that shows the currently selected [player] for a given [label]
/// (e.g. Striker / Non-striker / Bowler) and triggers a picker on tap.
class PlayerPickerTile extends StatelessWidget {
  const PlayerPickerTile({
    super.key,
    required this.label,
    required this.player,
    required this.onTap,
  });

  final String label;
  final TeamMemberModel? player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = player?.userHelper.getAvatar();
    final name = player?.userHelper.getDisplayName() ?? 'Select player';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(AppColors.dividerColor)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: 0.12),
              backgroundImage: avatar != null && avatar.isNotEmpty
                  ? NetworkImage(avatar)
                  : null,
              child: avatar == null || avatar.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: Color(AppColors.primaryColor),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}
