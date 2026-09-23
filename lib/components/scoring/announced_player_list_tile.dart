import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';

import '../../core/config/constants.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../announced_players/util/announced_player_display_helpers.dart';

/// Shared list row for announced-player pickers (avatar + name).
class AnnouncedPlayerListTile extends StatelessWidget {
  const AnnouncedPlayerListTile({
    super.key,
    required this.name,
    this.avatarUrl,
    this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  /// Convenience from an [AnnouncedPlayerModel].
  ///
  /// When [subtitle] is omitted, defaults to [announcedPlayerPickerSubtitle].
  factory AnnouncedPlayerListTile.fromPlayer(
    AnnouncedPlayerModel player, {
    Key? key,
    String? subtitle,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return AnnouncedPlayerListTile(
      key: key,
      name: player.name,
      avatarUrl: player.avatar,
      subtitle: subtitle ?? announcedPlayerPickerSubtitle(player),
      enabled: enabled,
      onTap: onTap,
    );
  }

  final String name;
  final String? avatarUrl;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final textColor = enabled
        ? const Color(AppColors.textColor)
        : const Color(AppColors.textSecondaryColor);

    return ListTile(
      enabled: enabled,
      leading: CircleAvatar(
        backgroundColor: const Color(
          AppColors.primaryColor,
        ).withValues(alpha: 0.12),
        backgroundImage: hasAvatar
            ? AppNetworkImage.provider(avatarUrl!)
            : null,
        child: hasAvatar
            ? null
            : Icon(
                Icons.person,
                color: enabled
                    ? const Color(AppColors.primaryColor)
                    : const Color(AppColors.textSecondaryColor),
              ),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
      onTap: enabled ? onTap : null,
    );
  }
}
