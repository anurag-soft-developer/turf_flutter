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
    ExploreCategory.match,
    ExploreCategory.team,
    ExploreCategory.player,
    ExploreCategory.post,
  ];

  static String label(ExploreCategory value) => switch (value) {
        ExploreCategory.all => 'All',
        ExploreCategory.match => 'Matches',
        ExploreCategory.team => 'Teams',
        ExploreCategory.player => 'Players',
        ExploreCategory.post => 'Posts',
      };

  @override
  Widget build(BuildContext context) {
    final tabs = <ExploreCategory>[
      if (includeAll) ExploreCategory.all,
      ..._concreteTabs,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final tab in tabs) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label(tab)),
                selected: category == tab,
                onSelected: (_) => onChanged(tab),
                selectedColor: const Color(AppColors.primaryColor).withValues(
                  alpha: 0.15,
                ),
                labelStyle: TextStyle(
                  color: category == tab
                      ? const Color(AppColors.primaryColor)
                      : const Color(AppColors.textSecondaryColor),
                  fontWeight:
                      category == tab ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: category == tab
                      ? const Color(AppColors.primaryColor)
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
