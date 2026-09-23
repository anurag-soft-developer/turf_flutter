import 'package:get/get.dart';

import '../../core/routes/route_query.dart';
import '../../team/model/team_model.dart';

/// Sports supported for unranked match creation (must match backend allowlist).
const unrankedMatchSports = <TeamSportType>{
  TeamSportType.cricket,
  TeamSportType.football,
};

class UnrankedMatchStartController extends GetxController {
  late final TeamSportType sport;

  bool get isSportSupported => unrankedMatchSports.contains(sport);

  String get screenTitle => 'Unranked ${sport.label.toLowerCase()}';

  String get sportLabel => sport.label.toLowerCase();

  @override
  void onInit() {
    super.onInit();
    sport = _sportFromRoute();
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
