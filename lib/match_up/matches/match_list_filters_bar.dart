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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Builder(
              builder: (fieldContext) => _CompactFilterField(
                fieldLabel: 'Type',
                icon: Icons.groups_outlined,
                label: filters.typeLabel,
                hasSelection: filters.hasTypeSelection,
                onTap: () => _openTypeMenu(fieldContext),
                onClear: () => onChanged(filters.withTypeAll()),
              ),
            ),
            const SizedBox(width: 6),
            Builder(
              builder: (fieldContext) => _CompactFilterField(
                fieldLabel: 'Status',
                icon: Icons.sports_score_outlined,
                label: filters.statusLabel,
                hasSelection: filters.hasStatusSelection,
                onTap: () => _openStatusMenu(fieldContext),
                onClear: () => onChanged(filters.withStatusAll()),
              ),
            ),
          ],
        ),
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
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: hasSelection ? primary : muted),
              const SizedBox(width: 4),
              Text(
                display,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                  color: hasSelection ? primary : muted,
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
