import 'package:flutter/material.dart';

import '../../../team/members/model/team_member_model.dart';
import 'player_picker_tile.dart';

/// Card grouping the striker / non-striker / bowler picker tiles.
class CricketPlayerSelector extends StatelessWidget {
  const CricketPlayerSelector({
    super.key,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.onTapStriker,
    required this.onTapNonStriker,
    required this.onTapBowler,
  });

  final TeamMemberModel? striker;
  final TeamMemberModel? nonStriker;
  final TeamMemberModel? bowler;
  final VoidCallback onTapStriker;
  final VoidCallback onTapNonStriker;
  final VoidCallback onTapBowler;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          PlayerPickerTile(
            label: 'Striker',
            player: striker,
            onTap: onTapStriker,
          ),
          const SizedBox(height: 8),
          PlayerPickerTile(
            label: 'Non-striker',
            player: nonStriker,
            onTap: onTapNonStriker,
          ),
          const SizedBox(height: 8),
          PlayerPickerTile(
            label: 'Bowler',
            player: bowler,
            onTap: onTapBowler,
          ),
        ],
      ),
    );
  }
}
