import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../team/model/team_model.dart';
import 'explore_team_chip_card.dart';

class ExploreTeamRow extends StatelessWidget {
  const ExploreTeamRow({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<TeamModel> items;

  static const double height = 140;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ExploreTeamChipCard(team: items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
