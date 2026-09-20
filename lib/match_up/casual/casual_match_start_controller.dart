import 'package:get/get.dart';

import '../../core/routes/route_query.dart';
import '../../team/model/team_model.dart';

/// Sports supported for casual match creation (must match backend allowlist).
const casualMatchSports = <TeamSportType>{
  TeamSportType.cricket,
  TeamSportType.football,
};

class CasualMatchStartController extends GetxController {
  late final TeamSportType sport;

  bool get isSportSupported => casualMatchSports.contains(sport);

  String get screenTitle => 'Casual ${sport.label.toLowerCase()}';

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
