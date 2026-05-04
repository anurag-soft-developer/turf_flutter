import 'package:flutter_application_1/bindings/match_challenges_binding.dart';
import 'package:flutter_application_1/bindings/match_up_binding.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/match_up/match_challenges/match_challenges_screen.dart';
import 'package:flutter_application_1/match_up/match_up_screen.dart';
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
];
