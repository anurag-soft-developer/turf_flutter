import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/chat/chat_thread_screen.dart';
import 'package:flutter_application_1/core/config/constants.dart';

import '../model/team_match_model.dart';

class MatchChallengeMessagesScreen extends StatelessWidget {
  final TeamMatchModel match;

  const MatchChallengeMessagesScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final matchId = match.id;
    final versus =
        '${match.fromTeamHelper.getDisplayName()} vs ${match.toTeamHelper.getDisplayName()}';

    if (matchId == null || matchId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: Text('Match not found.')),
      );
    }

    return ChatThreadScreen(
      scope: ChatScope.match,
      scopeId: matchId,
      title: versus,
    );
  }
}
