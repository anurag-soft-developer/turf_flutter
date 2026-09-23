import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import 'team_logo.dart';

/// One side of a pickable team-vs-team row (challenge sheet / unranked start).
class MatchPickVersusTeam {
  const MatchPickVersusTeam({
    required this.name,
    this.logoUrl = '',
    this.showEditBadge = false,
    this.placeholder = false,
    this.onTap,
    this.wrapLogo,
  });

  final String name;
  final String logoUrl;

  /// Pencil badge on the logo (editable side).
  final bool showEditBadge;

  /// Empty state: dashed-style circle with a + instead of a logo.
  final bool placeholder;

  /// Taps the whole column when set (and [wrapLogo] is null).
  final VoidCallback? onTap;

  /// Wrap the logo only — e.g. [MyTeamSelector] `buttonChild`.
  final Widget Function(Widget logo)? wrapLogo;
}

/// Avatar + name · VS · avatar + name, matching the challenge bottom sheet.
class MatchPickVersusRow extends StatelessWidget {
  const MatchPickVersusRow({
    super.key,
    required this.left,
    required this.right,
    this.logoSize = 75,
  });

  final MatchPickVersusTeam left;
  final MatchPickVersusTeam right;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _SideColumn(team: left, logoSize: logoSize)),
        Padding(
          padding: EdgeInsets.only(top: logoSize / 2 - 14, left: 8, right: 8),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(AppColors.primaryColor).withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(child: _SideColumn(team: right, logoSize: logoSize)),
      ],
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.team, required this.logoSize});

  final MatchPickVersusTeam team;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final logo = _EditableTeamLogo(
      logoUrl: team.logoUrl,
      size: logoSize,
      placeholder: team.placeholder,
      showEditBadge: team.showEditBadge,
    );
    final wrapped = team.wrapLogo != null ? team.wrapLogo!(logo) : logo;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        wrapped,
        const SizedBox(height: 8),
        Text(
          team.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: team.placeholder
                ? const Color(AppColors.textSecondaryColor)
                : const Color(AppColors.textColor),
          ),
        ),
      ],
    );

    if (team.wrapLogo != null || team.onTap == null) return column;

    return GestureDetector(
      onTap: team.onTap,
      behavior: HitTestBehavior.opaque,
      child: column,
    );
  }
}

class _EditableTeamLogo extends StatelessWidget {
  const _EditableTeamLogo({
    required this.logoUrl,
    required this.size,
    this.placeholder = false,
    this.showEditBadge = false,
  });

  final String logoUrl;
  final double size;
  final bool placeholder;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (placeholder)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    const Color(AppColors.primaryColor).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(AppColors.primaryColor)
                      .withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: size * 0.42,
                color: const Color(AppColors.primaryColor),
              ),
            )
          else
            TeamLogo(url: logoUrl, size: size),
          if (showEditBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryColor),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.edit, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
