import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';
import '../../rankings/player_avatar.dart';

/// Avatar + name row that navigates to the user's public profile.
class UserListTile extends StatelessWidget {
  const UserListTile({super.key, required this.helper});

  final UserFieldInstance helper;

  @override
  Widget build(BuildContext context) {
    final userId = helper.getId();
    final displayName = helper.getDisplayName();

    return ListTile(
      leading: PlayerAvatar(
        url: helper.getAvatar() ?? '',
        name: displayName,
        size: 44,
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(AppColors.textColor),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(AppColors.textSecondaryColor),
      ),
      onTap: userId == null || userId.isEmpty
          ? null
          : () => Get.toNamed(
              AppConstants.routes.teamMemberProfile,
              arguments: {'userId': userId},
            ),
    );
  }
}
