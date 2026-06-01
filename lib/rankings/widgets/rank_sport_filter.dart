import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../team/model/team_model.dart';
import '../../team/utils/team_ui.dart';

/// Sport filter banner + bottom sheet, styled like [MyTeamSelector].
class RankSportFilter extends StatelessWidget {
  const RankSportFilter({
    super.key,
    required this.value,
    required this.onChanged,
    this.sheetTitle = 'Select sport',
  });

  final TeamSportType value;
  final ValueChanged<TeamSportType> onChanged;
  final String sheetTitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSportPicker(context),
      child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(AppColors.dividerColor).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              _SportIconBadge(sport: value, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamSportLabel(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: Color(AppColors.textSecondaryColor),
              ),
            ],
          ),
        ),
    );
  }

  void _showSportPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  sheetTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                ),
                const SizedBox(height: 16),
                ...TeamSportType.values.map((sport) {
                  final isSelected = sport == value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? const Color(AppColors.primaryColor).withValues(
                              alpha: 0.08,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          onChanged(sport);
                          Navigator.pop(sheetContext);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.primaryColor)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _sportIcon(sport),
                                  color: const Color(AppColors.primaryColor),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  teamSportLabel(sport),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: const Color(AppColors.textColor),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  size: 22,
                                  color: Color(AppColors.primaryColor),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _sportIcon(TeamSportType sport) {
    switch (sport) {
      case TeamSportType.cricket:
        return Icons.sports_cricket;
      case TeamSportType.football:
        return Icons.sports_soccer;
    }
  }
}

class _SportIconBadge extends StatelessWidget {
  const _SportIconBadge({
    required this.sport,
    required this.size,
  });

  final TeamSportType sport;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
      ),
      child: Icon(
        RankSportFilter._sportIcon(sport),
        size: size * 0.64,
        color: const Color(AppColors.primaryColor),
      ),
    );
  }
}
