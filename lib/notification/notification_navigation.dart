import 'package:flutter_application_1/notification/model/notification_model.dart';

extension AppNotificationNavigation on AppNotification {
  String? get kind => data?['kind'] as String?;

  String? idFromData(String key) => data?[key]?.toString();

  /// Prefer data fields when sourceId is a different entity (e.g. teams).
  String? get bookingId => sourceId ?? idFromData('bookingId');
  String? get matchId => sourceId ?? idFromData('matchId');
  String? get teamId => idFromData('teamId');
  String? get turfId => sourceId ?? idFromData('turfId');
  String? get actorUserId => idFromData('actorUserId');
}
