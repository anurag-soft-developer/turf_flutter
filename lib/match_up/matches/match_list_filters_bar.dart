import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import 'match_list_filters.dart';

class MatchListFiltersBar extends StatelessWidget {
  const MatchListFiltersBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final MatchListFilters filters;
  final ValueChanged<MatchListFilters> onChanged;

  static const _filterWidth = 160.0;

  Future<void> _openTypeMenu(BuildContext context) async {
    final selected = await _showMenu<MatchTypeFilter>(
      context,
      items: [
        _menuItem(MatchTypeFilter.all, 'All'),
        _menuItem(MatchTypeFilter.my, 'My'),
      ],
    );
    if (selected == null) return;
    onChanged(filters.withType(selected));
  }

  Future<void> _openStatusMenu(BuildContext context) async {
    final selected = await _showMenu<MatchStatusFilter>(
      context,
      items: [
        _menuItem(MatchStatusFilter.all, 'All'),
        _menuItem(MatchStatusFilter.live, 'Live'),
        _menuItem(MatchStatusFilter.upcoming, 'Upcoming'),
        _menuItem(MatchStatusFilter.completed, 'Completed'),
      ],
    );
    if (selected == null) return;
    onChanged(filters.withStatus(selected));
  }

  PopupMenuItem<T> _menuItem<T>(T value, String label) {
    return PopupMenuItem<T>(
      value: value,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(AppColors.textColor),
          fontSize: 14,
        ),
      ),
    );
  }

  Future<T?> _showMenu<T>(
    BuildContext context, {
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
      position: position,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: _filterWidth,
            child: Builder(
              builder: (fieldContext) => _CompactFilterField(
                fieldLabel: 'Type',
                icon: Icons.groups_outlined,
                label: filters.typeLabel,
                hasSelection: filters.hasTypeSelection,
                onTap: () => _openTypeMenu(fieldContext),
                onClear: () => onChanged(filters.withTypeAll()),
              ),
            ),
          ),
          SizedBox(
            width: _filterWidth,
            child: Builder(
              builder: (fieldContext) => _CompactFilterField(
                fieldLabel: 'Status',
                icon: Icons.sports_score_outlined,
                label: filters.statusLabel,
                hasSelection: filters.hasStatusSelection,
                onTap: () => _openStatusMenu(fieldContext),
                onClear: () => onChanged(filters.withStatusAll()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFilterField extends StatelessWidget {
  const _CompactFilterField({
    required this.fieldLabel,
    required this.icon,
    required this.label,
    required this.hasSelection,
    required this.onTap,
    this.onClear,
  });

  final String fieldLabel;
  final IconData icon;
  final String label;
  final bool hasSelection;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            fieldLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
        ),
        SizedBox(
          height: _height,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(
                      AppColors.dividerColor,
                    ).withValues(alpha: 0.8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: const Color(AppColors.textSecondaryColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: Color(
                            hasSelection
                                ? AppColors.textColor
                                : AppColors.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: hasSelection && onClear != null
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: const Color(AppColors.textSecondaryColor),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: onClear,
                            )
                          : const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
