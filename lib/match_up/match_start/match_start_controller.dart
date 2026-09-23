import 'package:get/get.dart';

import '../../core/routes/route_query.dart';
import '../../team/model/team_model.dart';

/// Sports supported for scoreboard match start (must match backend allowlist).
const matchStartSports = <TeamSportType>{
  TeamSportType.cricket,
  TeamSportType.football,
};

class MatchStartController extends GetxController {
  late final TeamSportType sport;
  late final bool isRanked;

  bool get isSportSupported => matchStartSports.contains(sport);

  String get modeLabel => isRanked ? 'Ranked' : 'Unranked';

  String get screenTitle => '$modeLabel ${sport.label.toLowerCase()}';

  String get sportLabel => sport.label.toLowerCase();

  @override
  void onInit() {
    super.onInit();
    sport = _sportFromRoute();
    isRanked = routeParam('mode') == 'ranked';
  }

  static TeamSportType sportFromRoute() {
    String? raw;
    final args = Get.arguments;
    if (args is Map) {
      raw = args['sport']?.toString().trim();
    }
    raw ??= routeParam('sport');
    if (raw != null && raw.isNotEmpty) {
      for (final candidate in TeamSportType.values) {
        if (candidate.name == raw) {
          return candidate;
        }
      }
    }
    return TeamSportType.cricket;
  }

  TeamSportType _sportFromRoute() => sportFromRoute();
}
