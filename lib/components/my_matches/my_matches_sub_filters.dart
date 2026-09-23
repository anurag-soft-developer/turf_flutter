import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../match_up/my_matches/my_matches_controller.dart';
import '../match_up/my_team_selector.dart';
import '../../core/config/constants.dart';

/// Team + ranked/unranked chips under the My Matches tabs. Shared by every tab.
class MyMatchesSubFilters extends StatelessWidget {
  const MyMatchesSubFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MyMatchesController>();
    return Obx(() {
      final allTeams = c.filterAllTeams.value;
      final teamName = c.selectedMembershipTeam.value?.name;
      final type = c.typeFilter.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              MyTeamSelector(
                teams: c.myTeams,
                allowToSelectAll: true,
                allTeamsSelected: allTeams,
                selectedTeam: c.selectedMembershipTeam.value,
                sheetTitle: 'Show matches for',
                allTeamsLabel: 'All',
                onTeamSelected: c.selectTeamForFilter,
                onAllTeamsSelected: c.selectAllTeamsFilter,
                buttonChild: _FilterChip(
                  fieldLabel: 'Team',
                  icon: Icons.groups_outlined,
                  label: allTeams ? 'All' : (teamName ?? 'Team'),
                  hasSelection: !allTeams,
                  onClear: allTeams ? null : c.selectAllTeamsFilter,
                ),
              ),
              const SizedBox(width: 6),
              Builder(
                builder: (fieldContext) => _FilterChip(
                  fieldLabel: 'Type',
                  icon: Icons.emoji_events_outlined,
                  label: type.menuLabel,
                  hasSelection: type.hasSelection,
                  onTap: () => _openTypeMenu(fieldContext, c),
                  onClear: type.hasSelection
                      ? () => c.setTypeFilter(MyMatchesTypeFilter.all)
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _openTypeMenu(
    BuildContext context,
    MyMatchesController controller,
  ) async {
    final box = context.findRenderObject()! as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<MyMatchesTypeFilter>(
      context: context,
      initialValue: controller.typeFilter.value,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        offset.dy,
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      items: [
        for (final value in MyMatchesTypeFilter.values)
          PopupMenuItem(
            value: value,
            child: Text(
              value.menuLabel,
              style: const TextStyle(
                color: Color(AppColors.textColor),
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
    if (selected == null) return;
    controller.setTypeFilter(selected);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.fieldLabel,
    required this.icon,
    required this.label,
    required this.hasSelection,
    this.onTap,
    this.onClear,
  });

  final String fieldLabel;
  final IconData icon;
  final String label;
  final bool hasSelection;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  static const _height = 28.0;
  static const _selectedBg = Color(0xFFE0E7FF);

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    final muted = const Color(AppColors.textSecondaryColor);
    final display = hasSelection ? label : fieldLabel;

    return Material(
      color: hasSelection ? _selectedBg : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: _height,
          padding: const EdgeInsets.only(left: 8, right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasSelection
                  ? primary
                  : const Color(AppColors.dividerColor),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: hasSelection ? primary : muted),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight:
                        hasSelection ? FontWeight.w600 : FontWeight.w500,
                    color: hasSelection ? primary : muted,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              if (hasSelection && onClear != null)
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 12, color: muted),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
