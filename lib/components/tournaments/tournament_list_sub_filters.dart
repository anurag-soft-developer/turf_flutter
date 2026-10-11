import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../rankings/widgets/rank_sport_filter.dart';
import '../../team/model/team_model.dart';
import '../../tournament/list/tournament_list_controller.dart';

/// Sport chip under tournament tabs — same pattern as My Matches sub-filters.
class TournamentListSubFilters extends StatelessWidget {
  const TournamentListSubFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TournamentListController>();
    return Obx(() {
      final sport = c.sportFilter.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Builder(
                builder: (fieldContext) => _FilterChip(
                  fieldLabel: 'Sport',
                  icon: Icons.sports_outlined,
                  label: sport?.label ?? 'All',
                  hasSelection: sport != null,
                  onTap: () => SportFilterPicker.showSheet(
                    context: fieldContext,
                    value: sport,
                    sports: rankingTeamSportTypes,
                    sheetTitle: 'Filter by sport',
                    includeAll: true,
                    onChanged: c.setSportFilter,
                  ),
                  onClear:
                      sport != null ? () => c.setSportFilter(null) : null,
                ),
              ),
            ],
          ),
        ),
      );
    });
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
