import '../../turf/model/turf_model.dart';

class PlayerDashboardModel {
  final String turfsTitle;
  final List<TurfModel> turfs;
  final int nearbyTeamsCount;
  final int unreadNotificationCount;

  const PlayerDashboardModel({
    required this.turfsTitle,
    required this.turfs,
    required this.nearbyTeamsCount,
    required this.unreadNotificationCount,
  });

  factory PlayerDashboardModel.fromJson(Map<String, dynamic> json) {
    final rawTurfs = json['turfs'] as List<dynamic>? ?? const [];
    final rawTitle = (json['turfsTitle'] as String?)?.trim();
    return PlayerDashboardModel(
      turfsTitle: _normalizeTurvesTitle(
        rawTitle == null || rawTitle.isEmpty ? null : rawTitle,
      ),
      turfs: rawTurfs
          .whereType<Map<String, dynamic>>()
          .map(TurfModel.fromJson)
          .toList(),
      nearbyTeamsCount: (json['nearbyTeamsCount'] as num?)?.toInt() ?? 0,
      unreadNotificationCount:
          (json['unreadNotificationCount'] as num?)?.toInt() ?? 0,
    );
  }

  static String _normalizeTurvesTitle(String? title) {
    if (title == null || title.isEmpty) return 'Featured turves';
    return title.replaceAll(RegExp(r'\bturfs\b', caseSensitive: false), 'turves');
  }

  static const empty = PlayerDashboardModel(
    turfsTitle: 'Featured turves',
    turfs: [],
    nearbyTeamsCount: 0,
    unreadNotificationCount: 0,
  );
}
