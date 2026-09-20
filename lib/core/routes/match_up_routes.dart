import 'package:flutter/material.dart';

import 'package:flutter_application_1/bindings/explore_binding.dart';
import 'package:flutter_application_1/bindings/match_challenge_detail_binding.dart';
import 'package:flutter_application_1/bindings/match_challenges_binding.dart';
import 'package:flutter_application_1/bindings/my_matches_binding.dart';
import 'package:flutter_application_1/bindings/scoring_binding.dart';
import 'package:flutter_application_1/core/components/app_bar/app_bar_background.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/core/routes/route_query.dart';
import 'package:flutter_application_1/explore/explore_screen.dart';
import 'package:flutter_application_1/explore/search/explore_search_screen.dart';
import 'package:flutter_application_1/explore/widgets/explore_post_viewer_screen.dart';
import 'package:flutter_application_1/match_up/casual/casual_match_start_binding.dart';
import 'package:flutter_application_1/match_up/casual/casual_match_start_screen.dart';
import 'package:flutter_application_1/match_up/match_challenges/match_challenge_detail_screen.dart';
import 'package:flutter_application_1/match_up/match_challenges/match_challenges_screen.dart';
import 'package:flutter_application_1/match_up/my_matches/my_matches_screen.dart';
import 'package:flutter_application_1/match_up/messages/match_challenge_messages_screen.dart';
import 'package:flutter_application_1/match_up/model/team_match_model.dart';
import 'package:flutter_application_1/scoring/cricket/cricket_scoreboard_screen.dart';
import 'package:flutter_application_1/scoring/football/football_scoreboard_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> matchUpRoutes = [
  GetPage(
    name: AppConstants.routes.matchUpChallenges,
    page: () => const MatchChallengesScreen(),
    binding: MatchChallengesBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.myMatches,
    page: () => const MyMatchesScreen(),
    binding: MyMatchesBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.matchUpCasual,
    page: () => const CasualMatchStartScreen(),
    binding: CasualMatchStartBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.matches,
    page: () => const ExploreScreen(),
    binding: ExploreBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.exploreSearch,
    page: () => const ExploreSearchScreen(),
    binding: ExploreSearchBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.explorePost(),
    page: () => const ExplorePostViewerScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.matchChallengeDetail(),
    page: () {
      final args = Get.arguments;
      final fromArgs = args is Map ? args['matchId']?.toString().trim() : null;
      final fromRoute = routeParam('id');
      final id = (fromRoute != null && fromRoute.isNotEmpty)
          ? fromRoute
          : (fromArgs ?? '');
      return MatchChallengeDetailScreen(matchId: id);
    },
    binding: MatchChallengeDetailBinding(),
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
          appBar: AppAppBar(title: const Text('Messages')),
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
  GetPage(
    name: AppConstants.routes.footballScoreBoard,
    page: () => const FootballScoreboardScreen(),
    binding: ScoringBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
