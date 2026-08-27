import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../model/explore_category.dart';

class ExploreSearchCategoryTabs extends StatelessWidget {
  const ExploreSearchCategoryTabs({
    super.key,
    required this.category,
    required this.onChanged,
    this.includeAll = false,
  });

  final ExploreCategory category;
  final ValueChanged<ExploreCategory> onChanged;
  final bool includeAll;

  static const _concreteTabs = <ExploreCategory>[
    ExploreCategory.post,
    ExploreCategory.match,
    ExploreCategory.team,
    ExploreCategory.player,
  ];

  /// Theme-matched indigo tint (between washed-out and solid primary).
  static const _selectedBg = Color(0xFFE0E7FF);

  static String label(ExploreCategory value) => switch (value) {
        ExploreCategory.all => 'All',
        ExploreCategory.match => 'Matches',
        ExploreCategory.team => 'Teams',
        ExploreCategory.player => 'Players',
        ExploreCategory.post => 'Posts',
      };

  static IconData icon(ExploreCategory value) => switch (value) {
        ExploreCategory.all => Icons.grid_view_rounded,
        ExploreCategory.match => Icons.sports_outlined,
        ExploreCategory.team => Icons.groups_outlined,
        ExploreCategory.player => Icons.person_outline,
        ExploreCategory.post => Icons.dynamic_feed_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final tabs = <ExploreCategory>[
      if (includeAll) ExploreCategory.all,
      ..._concreteTabs,
    ];
    final primary = const Color(AppColors.primaryColor);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final tab in tabs) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  icon(tab),
                  size: 16,
                  color: category == tab
                      ? primary
                      : const Color(AppColors.textSecondaryColor),
                ),
                label: Text(label(tab)),
                selected: category == tab,
                onSelected: (_) => onChanged(tab),
                showCheckmark: false,
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _selectedBg;
                  }
                  return Colors.white;
                }),
                labelStyle: TextStyle(
                  color: category == tab
                      ? primary
                      : const Color(AppColors.textSecondaryColor),
                  fontWeight:
                      category == tab ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: category == tab
                      ? primary
                      : const Color(AppColors.dividerColor),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
