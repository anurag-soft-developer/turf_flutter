import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

class AppTabItem {
  const AppTabItem({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.controller,
    required this.items,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.isScrollable = false,
  });

  final TabController controller;
  final List<AppTabItem> items;
  final ValueChanged<int>? onTap;
  final EdgeInsetsGeometry padding;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Auto-switch to scroll mode when tabs cannot fit comfortably.
          const minTabWidth = 112.0;
          const outerHorizontalPadding = 24.0; // left + right
          final neededWidth = (items.length * minTabWidth) + outerHorizontalPadding;
          final shouldScroll = isScrollable || neededWidth > constraints.maxWidth;

          return Container(
            decoration: BoxDecoration(
              color: const Color(AppColors.primaryColor).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(AppColors.dividerColor).withValues(alpha: 0.35),
              ),
            ),
            child: TabBar(
              controller: controller,
              onTap: onTap,
              isScrollable: shouldScroll,
              tabAlignment: shouldScroll ? TabAlignment.start : null,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(AppColors.primaryColor),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(AppColors.textSecondaryColor),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelPadding: EdgeInsets.symmetric(horizontal: shouldScroll ? 14 : 8),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: items
                  .map(
                    (item) => Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.icon != null) ...[
                            Icon(item.icon, size: 16),
                            const SizedBox(width: 6),
                          ],
                          Text(item.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class AppSegmentedTabView extends StatelessWidget {
  const AppSegmentedTabView({
    super.key,
    required this.controller,
    required this.children,
    this.physics,
  });

  final TabController controller;
  final List<Widget> children;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: controller,
      physics: physics,
      children: children,
    );
  }
}
