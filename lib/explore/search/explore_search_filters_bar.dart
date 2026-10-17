import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      ExploreCategory.post => _PostsFiltersBar(
          filters: filters,
          onChanged: onChanged,
        ),
      ExploreCategory.all || ExploreCategory.player => const SizedBox.shrink(),
    };
  }
}

class _PostsFiltersBar extends StatelessWidget {
  const _PostsFiltersBar({
    required this.filters,
    required this.onChanged,
  });

  final ExploreFilters filters;
  final ValueChanged<ExploreFilters> onChanged;

  Future<void> _openTypeMenu(BuildContext context) async {
    final selected = await _showMenu<ExplorePostKind>(
      context,
      initialValue: filters.postKind,
      items: [
        for (final kind in ExplorePostKind.values)
          PopupMenuItem(
            value: kind,
            child: Text(
              kind.label,
              style: const TextStyle(
                color: Color(AppColors.textColor),
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
    if (selected == null) return;
    onChanged(filters.copyWith(postKind: selected));
  }

  Future<T?> _showMenu<T>(
    BuildContext context, {
    required T initialValue,
    required List<PopupMenuEntry<T>> items,
  }) {
    final box = context.findRenderObject()! as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + box.size.height,
      offset.dx + box.size.width,
      offset.dy,
    );
    return showMenu<T>(
      context: context,
      initialValue: initialValue,
      position: position,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = filters.postKind != ExplorePostKind.all;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Builder(
            builder: (fieldContext) => _SubFilterChip(
              label: selected ? filters.postKind.label : 'Type',
              icon: Icons.dynamic_feed_outlined,
              selected: selected,
              showChevron: !selected,
              onTap: () => _openTypeMenu(fieldContext),
              onClear: selected
                  ? () => onChanged(
                        filters.copyWith(postKind: ExplorePostKind.all),
                      )
                  : null,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PostsShortcut(
                      icon: Icons.campaign_outlined,
                      label: 'My openings',
                      onPressed: () =>
                          Get.toNamed(AppConstants.routes.myOpenings),
                    ),
                    _PostsShortcut(
                      icon: Icons.how_to_reg_outlined,
                      label: 'My submissions',
                      onPressed: () =>
                          Get.toNamed(AppConstants.routes.myJoinRequests),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostsShortcut extends StatelessWidget {
  const _PostsShortcut({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
