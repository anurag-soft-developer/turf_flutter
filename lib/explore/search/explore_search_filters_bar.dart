import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../match_up/matches/match_list_filters_bar.dart';
import '../../rankings/widgets/rank_sport_filter.dart';
import '../../team/model/team_model.dart';
import '../model/explore_category.dart';
import '../model/explore_filters.dart';

class ExploreSearchFiltersBar extends StatelessWidget {
  const ExploreSearchFiltersBar({
    super.key,
    required this.category,
    required this.filters,
    required this.onChanged,
  });

  final ExploreCategory category;
  final ExploreFilters filters;
  final ValueChanged<ExploreFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (category) {
      ExploreCategory.match => MatchListFiltersBar(
          filters: filters.matchFilters,
          onChanged: (next) => onChanged(
            filters.copyWith(matchFilters: next),
          ),
        ),
      ExploreCategory.team => _TeamFiltersBar(
          filters: filters,
          onChanged: onChanged,
        ),
      ExploreCategory.all ||
      ExploreCategory.player ||
      ExploreCategory.post =>
        const SizedBox.shrink(),
    };
  }
}

class _TeamFiltersBar extends StatelessWidget {
  const _TeamFiltersBar({
    required this.filters,
    required this.onChanged,
  });

  final ExploreFilters filters;
  final ValueChanged<ExploreFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SubFilterChip(
              label: filters.sportType == null
                  ? 'Sport'
                  : filters.sportType!.name,
              icon: Icons.sports_outlined,
              selected: filters.sportType != null,
              showChevron: filters.sportType == null,
              onTap: () => _pickSport(context),
              onClear: filters.sportType == null
                  ? null
                  : () => onChanged(filters.copyWith(clearSportType: true)),
            ),
            const SizedBox(width: 6),
            _SubFilterChip(
              label: 'Open for match',
              selected: filters.teamOpenForMatch == true,
              onTap: () {
                if (filters.teamOpenForMatch == true) {
                  onChanged(filters.copyWith(clearTeamOpenForMatch: true));
                } else {
                  onChanged(filters.copyWith(teamOpenForMatch: true));
                }
              },
            ),
            const SizedBox(width: 6),
            _SubFilterChip(
              label: 'Recruiting',
              selected: filters.lookingForMembers == true,
              onTap: () {
                if (filters.lookingForMembers == true) {
                  onChanged(filters.copyWith(clearLookingForMembers: true));
                } else {
                  onChanged(filters.copyWith(lookingForMembers: true));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSport(BuildContext context) async {
    await SportFilterPicker.showSheet(
      context: context,
      value: filters.sportType,
      sports: TeamSportType.values,
      searchable: true,
      onChanged: (sport) {
        if (sport != null) {
          onChanged(filters.copyWith(sportType: sport));
        }
      },
    );
  }
}

/// Compact secondary pill — white surface so it reads on the primary header.
class _SubFilterChip extends StatelessWidget {
  const _SubFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.showChevron = false,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool showChevron;
  final VoidCallback? onClear;

  static const _selectedBg = Color(0xFFE0E7FF);
  static const _height = 28.0;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    final muted = const Color(AppColors.textSecondaryColor);

    return Material(
      color: selected ? _selectedBg : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: _height,
          padding: const EdgeInsets.only(left: 8, right: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? primary : muted),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? primary : muted,
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: muted),
              ],
              if (selected && onClear != null) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 12, color: muted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
