import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../core/models/team/team_member_field_instance.dart';
import 'team_logo.dart';

/// Banner + bottom sheet to pick a team, optionally including **All my teams**.
class MyTeamSelector extends StatelessWidget {
  const MyTeamSelector({
    super.key,
    required this.teams,
    required this.allowToSelectAll,
    required this.allTeamsSelected,
    required this.selectedTeam,
    required this.bannerTitle,
    required this.sheetTitle,
    required this.onTeamSelected,
    this.onAllTeamsSelected,
    this.allTeamsLabel = 'All my teams',
    this.actionChipLabel = 'Switch',
  }) : assert(
          !allowToSelectAll || onAllTeamsSelected != null,
          'onAllTeamsSelected is required when allowToSelectAll is true',
        );

  final List<TeamMemberFieldInstance> teams;

  /// When true, sheet lists [allTeamsLabel] first and [allTeamsSelected] drives the banner.
  final bool allowToSelectAll;
  final bool allTeamsSelected;
  final TeamMemberFieldInstance? selectedTeam;

  final String bannerTitle;
  final String sheetTitle;
  final String allTeamsLabel;
  final String actionChipLabel;

  final void Function(TeamMemberFieldInstance team) onTeamSelected;
  final VoidCallback? onAllTeamsSelected;

  String get _bannerValue {
    if (allowToSelectAll && allTeamsSelected) return allTeamsLabel;
    return selectedTeam?.name ?? 'Select team';
  }

  bool get _tappable {
    if (teams.isEmpty) return false;
    if (allowToSelectAll) return true;
    return teams.length > 1;
  }

  bool get _showActionChip => teams.length > 1;

  @override
  Widget build(BuildContext context) {
    if (!allowToSelectAll && selectedTeam == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(AppColors.backgroundColor),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: GestureDetector(
        onTap: _tappable ? () => _showTeamPicker(context) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(AppColors.primaryColor)
                    .withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _bannerLeading(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bannerTitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _bannerValue,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_showActionChip && _tappable)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        actionChipLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerLeading() {
    if (allowToSelectAll && allTeamsSelected) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Icon(Icons.groups, size: 18, color: Colors.white),
      );
    }

    final sel = selectedTeam;
    if (sel == null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Icon(Icons.filter_list, size: 18, color: Colors.white),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: sel.logo.isEmpty
          ? const Icon(Icons.shield_outlined, size: 16, color: Colors.white)
          : ClipOval(
              child: Image.network(
                sel.logo,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  void _showTeamPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              sheetTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 16),
            if (allowToSelectAll) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: allTeamsSelected
                      ? const Color(AppColors.primaryColor).withValues(
                          alpha: 0.08,
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      onAllTeamsSelected!();
                      Navigator.pop(sheetContext);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(AppColors.primaryColor)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.groups,
                              color: Color(AppColors.primaryColor),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              allTeamsLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(AppColors.textColor),
                              ),
                            ),
                          ),
                          if (allTeamsSelected)
                            const Icon(
                              Icons.check_circle,
                              size: 22,
                              color: Color(AppColors.primaryColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            ...teams.map((team) {
              final isSelected = allowToSelectAll
                  ? !allTeamsSelected && selectedTeam?.id == team.id
                  : selectedTeam?.id == team.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected
                      ? const Color(AppColors.primaryColor)
                          .withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      onTeamSelected(team);
                      Navigator.pop(sheetContext);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          TeamLogo(url: team.logo, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              team.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: const Color(AppColors.textColor),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              size: 22,
                              color: Color(AppColors.primaryColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
