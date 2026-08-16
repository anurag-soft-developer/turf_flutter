import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../match_up/matches/match_list_filters_bar.dart';
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
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _FilterChip(
            label: filters.sportType == null
                ? 'Sport'
                : 'Sport: ${filters.sportType!.name}',
            selected: filters.sportType != null,
            onTap: () => _pickSport(context),
            onClear: filters.sportType == null
                ? null
                : () => onChanged(filters.copyWith(clearSportType: true)),
          ),
          _FilterChip(
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
          _FilterChip(
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
    );
  }

  Future<void> _pickSport(BuildContext context) async {
    final sports = TeamSportType.values;
    final picked = await showModalBottomSheet<TeamSportType>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select sport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final sport in sports)
                ListTile(
                  title: Text(sport.name),
                  onTap: () => Navigator.pop(ctx, sport),
                ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      onChanged(filters.copyWith(sportType: picked));
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: selected && onClear != null
          ? GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 16),
            )
          : null,
      backgroundColor: selected
          ? const Color(0xFFE0E7FF)
          : Colors.white,
      side: BorderSide(
        color: selected
            ? const Color(AppColors.primaryColor)
            : const Color(AppColors.dividerColor),
      ),
      labelStyle: TextStyle(
        color: selected
            ? const Color(AppColors.primaryColor)
            : const Color(AppColors.textSecondaryColor),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
