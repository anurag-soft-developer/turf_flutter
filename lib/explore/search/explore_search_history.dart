import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

class ExploreSearchHistory extends StatelessWidget {
  const ExploreSearchHistory({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<String> items;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.history,
                size: 48,
                color: Color(AppColors.textSecondaryColor),
              ),
              SizedBox(height: 12),
              Text(
                'No recent searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your search history will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent searches',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                foregroundColor: const Color(AppColors.textSecondaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...items.map(
          (term) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HistoryTile(
              term: term,
              onTap: () => onSelect(term),
              onRemove: () => onRemove(term),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Icon(
                Icons.history,
                size: 20,
                color: Color(AppColors.textSecondaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  term,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(AppColors.textSecondaryColor),
                ),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
