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
    return PlayerDashboardModel(
      turfsTitle: (json['turfsTitle'] as String?)?.trim().isNotEmpty == true
          ? json['turfsTitle'] as String
          : 'Featured turfs',
      turfs: rawTurfs
          .whereType<Map<String, dynamic>>()
          .map(TurfModel.fromJson)
          .toList(),
      nearbyTeamsCount: (json['nearbyTeamsCount'] as num?)?.toInt() ?? 0,
      unreadNotificationCount:
          (json['unreadNotificationCount'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = PlayerDashboardModel(
    turfsTitle: 'Featured turfs',
    turfs: [],
    nearbyTeamsCount: 0,
    unreadNotificationCount: 0,
  );
}
