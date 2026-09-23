import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../match_up/announced_players/model/announced_player_model.dart';

/// Picker/list subtitle: Substitute and/or Guest; null when neither.
String? announcedPlayerPickerSubtitle(AnnouncedPlayerModel p) {
  final parts = <String>[];
  if (p.isSubstitute) parts.add('Substitute');
  if (p.isGuest) parts.add('Guest');
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

/// Compact C / VC / SUB chips for avatar stacks and list trailing.
class AnnouncedPlayerBadgeRow extends StatelessWidget {
  const AnnouncedPlayerBadgeRow({
    super.key,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.isSubstitute,
    this.compact = false,
    this.axis = Axis.vertical,
  });

  final bool isCaptain;
  final bool isViceCaptain;
  final bool isSubstitute;
  final bool compact;
  final Axis axis;

  bool get hasAny => isCaptain || isViceCaptain || isSubstitute;

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();

    final chips = <Widget>[
      if (isCaptain)
        const Tooltip(
          message: 'Captain',
          child: AnnouncedPlayerLeadershipChip(
            label: 'C',
            foreground: Color(AppColors.primaryColor),
            background: Colors.white,
            compact: true,
          ),
        ),
      if (isViceCaptain)
        const Tooltip(
          message: 'Vice-captain',
          child: AnnouncedPlayerLeadershipChip(
            label: 'VC',
            foreground: Color(AppColors.secondaryColor),
            background: Colors.white,
            compact: true,
          ),
        ),
      if (isSubstitute)
        const Tooltip(
          message: 'Substitute',
          child: AnnouncedPlayerLeadershipChip(
            label: 'SUB',
            foreground: Color(AppColors.textSecondaryColor),
            background: Colors.white,
            compact: true,
          ),
        ),
    ];

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            chips[i],
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(height: 3),
          chips[i],
        ],
      ],
    );
  }
}

class AnnouncedPlayerLeadershipChip extends StatelessWidget {
  const AnnouncedPlayerLeadershipChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.compact = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padH = compact ? 5.0 : 8.0;
    final padV = compact ? 2.0 : 3.0;
    final fontSize = compact ? 9.0 : 10.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
        boxShadow: compact
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: foreground,
        ),
      ),
    );
  }
}
