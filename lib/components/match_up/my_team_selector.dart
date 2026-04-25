import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../core/models/team/team_member_field_instance.dart';
import 'team_logo.dart';

/// Banner + bottom sheet to pick a team, optionally including **All my teams**.
class MyTeamSelector extends StatelessWidget {
  const MyTeamSelector({
    super.key,
    required this.teams,
    required this.onTeamSelected,
    this.selectedTeam,
    this.allTeamsSelected = false,
    this.sheetTitle = 'Select your team',
    this.allowToSelectAll = false,
    this.onAllTeamsSelected,
    this.allTeamsLabel = 'All',
    this.buttonChild,
    this.trimLabel = false,
  }) : assert(
         !allowToSelectAll || onAllTeamsSelected != null,
         'onAllTeamsSelected is required when allowToSelectAll is true',
       );

  final List<TeamMemberFieldInstance> teams;

  /// When true, sheet lists [allTeamsLabel] first and [allTeamsSelected] drives the banner.
  final bool allowToSelectAll;
  final bool allTeamsSelected;
  final TeamMemberFieldInstance? selectedTeam;

  final String sheetTitle;
  final String allTeamsLabel;
  final Widget? buttonChild;
  final bool trimLabel;

  final void Function(TeamMemberFieldInstance team) onTeamSelected;
  final VoidCallback? onAllTeamsSelected;

  String get _bannerValue {
    final maxLength = 10;
    late String name = selectedTeam?.name ?? 'Select team';
    if (allowToSelectAll && allTeamsSelected) {
      name = allTeamsLabel;
    } else {
      name = selectedTeam?.name ?? 'Select team';
    }
    if (trimLabel) {
      name =
          '${name.substring(0, name.length > maxLength ? maxLength : name.length)}${name.length > maxLength ? '...' : ''}';
    }
    return name;
  }

  bool get _tappable {
    if (teams.isEmpty) return false;
    if (allowToSelectAll) return true;
    return teams.length > 1;
  }

  // bool get _showActionChip => teams.length > 1;

  @override
  Widget build(BuildContext context) {
    if (buttonChild != null) {
      return GestureDetector(
        onTap: _tappable ? () => _showTeamPicker(context) : null,
        child: buttonChild!,
      );
    }

    if (!allowToSelectAll && selectedTeam == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _tappable ? () => _showTeamPicker(context) : null,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(AppColors.primaryColor).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(AppColors.dividerColor).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            _bannerLeading(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _bannerValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: Color(AppColors.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerLeading() {
    if (allowToSelectAll && allTeamsSelected) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(AppColors.primaryColor).withValues(alpha: 0.1),
        ),
        child: const Icon(
          Icons.groups,
          size: 14,
          color: Color(AppColors.primaryColor),
        ),
      );
    }

    final sel = selectedTeam;
    if (sel == null) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(AppColors.primaryColor).withValues(alpha: 0.1),
        ),
        child: Icon(
          Icons.filter_list,
          size: 14,
          color: Color(AppColors.primaryColor),
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(AppColors.primaryColor).withValues(alpha: 0.1),
      ),
      child: sel.logo.isEmpty
          ? Icon(
              Icons.shield_outlined,
              size: 14,
              color: Color(AppColors.primaryColor),
            )
          : ClipOval(
              child: Image.network(
                sel.logo,
                width: 22,
                height: 22,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ),
    );
  }

  void _showTeamPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.75;
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              height: maxHeight,
              child: Column(
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
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(sheetContext).viewPadding.bottom + 8,
                      ),
                      children: [
                        if (allowToSelectAll) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: allTeamsSelected
                                  ? const Color(
                                      AppColors.primaryColor,
                                    ).withValues(alpha: 0.08)
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
                                          color: const Color(
                                            AppColors.primaryColor,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                  ? const Color(
                                      AppColors.primaryColor,
                                    ).withValues(alpha: 0.08)
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
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: const Color(
                                              AppColors.textColor,
                                            ),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
