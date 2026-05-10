import 'package:flutter/material.dart';

import '../../components/challenges/challenge_messages_placeholder.dart';
import '../../core/config/constants.dart';
import '../model/team_match_model.dart';

class MatchChallengeMessagesScreen extends StatelessWidget {
  final TeamMatchModel match;

  const MatchChallengeMessagesScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final versus =
        '${match.fromTeamHelper.getDisplayName()} vs ${match.toTeamHelper.getDisplayName()}';

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                versus,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ),
          ),
        ),
      ),
      body: const ChallengeMessagesPlaceholder(),
    );
  }
}
