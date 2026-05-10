import 'package:flutter/material.dart';

import 'package:flutter_application_1/bindings/match_challenges_binding.dart';
import 'package:flutter_application_1/bindings/match_up_binding.dart';
import 'package:flutter_application_1/bindings/scoring_binding.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/match_up/match_challenges/match_challenges_screen.dart';
import 'package:flutter_application_1/match_up/match_up_screen.dart';
import 'package:flutter_application_1/match_up/messages/match_challenge_messages_screen.dart';
import 'package:flutter_application_1/match_up/model/team_match_model.dart';
import 'package:flutter_application_1/scoring/cricket_scoreboard_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> matchUpRoutes = [
  GetPage(
    name: AppConstants.routes.matchUp,
    page: () => const MatchUpScreen(),
    binding: MatchUpBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.matchUpChallenges,
    page: () => const MatchChallengesScreen(),
    binding: MatchChallengesBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.matchChallengeMessages,
    page: () {
      final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
      final match = args['match'] as TeamMatchModel?;
      if (match == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Messages')),
          body: const Center(
            child: Text(
              'Missing challenge data. Go back and open messages again.',
            ),
          ),
        );
      }
      return MatchChallengeMessagesScreen(match: match);
    },
    binding: MatchChallengesBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.cricketScoreBoard,
    page: () => const CricketScoreBoardScreen(),
    binding: ScoringBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
