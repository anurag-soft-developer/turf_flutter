import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../team/model/team_model.dart';

class SportTabs extends StatelessWidget {
  const SportTabs({super.key, required this.selected, required this.onChanged});

  final TeamSportType selected;
  final ValueChanged<TeamSportType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: TeamSportType.values.map((sport) {
          final isActive = sport == selected;
          final label = sport == TeamSportType.cricket ? 'Cricket' : 'Football';
          final icon = sport == TeamSportType.cricket
              ? Icons.sports_cricket
              : Icons.sports_soccer;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: isActive
                    ? const Color(AppColors.primaryColor)
                    : const Color(
                        AppColors.primaryColor,
                      ).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChanged(sport),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: isActive ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isActive ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
