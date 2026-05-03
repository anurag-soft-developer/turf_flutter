import 'package:flutter_application_1/core/models/user/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

/// Stored notification document (`GET /notifications`, etc.).
@JsonSerializable(explicitToJson: true)
class AppNotification {
  @JsonKey(name: '_id')
  final String id;
  @JsonKey(name: 'recipientUserId')
  final String recipientUserId;
  @JsonKey(
    name: 'module',
    fromJson: notificationRecordModuleFromJson,
    toJson: notificationRecordModuleToJson,
  )
  final NotificationModule module;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? sourceType;
  final String? sourceId;
  @JsonKey(name: 'readAt')
  final String? readAt;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  const AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.module,
    required this.title,
    required this.body,
    this.data,
    this.sourceType,
    this.sourceId,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  bool get isRead => readAt != null && readAt!.isNotEmpty;

  DateTime? get readAtDate => _parseIso(readAt);
  DateTime? get createdAtDate => _parseIso(createdAt);
  DateTime? get updatedAtDate => _parseIso(updatedAt);
}

DateTime? _parseIso(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return null;
  }
}

NotificationModule notificationRecordModuleFromJson(Object? json) {
  if (json is! String) return NotificationModule.turfBooking;
  return notificationModuleFromApiString(json) ?? NotificationModule.turfBooking;
}

Object notificationRecordModuleToJson(NotificationModule module) =>
    module.apiKey;

/// Matches server `CreateNotificationDto` (typically internal; included for parity).
@JsonSerializable(explicitToJson: true)
class CreateNotificationRequest {
  final String recipientUserId;
  @JsonKey(
    fromJson: notificationRecordModuleFromJson,
    toJson: notificationRecordModuleToJson,
  )
  final NotificationModule module;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? sourceType;
  final String? sourceId;

  const CreateNotificationRequest({
    required this.recipientUserId,
    required this.module,
    required this.title,
    required this.body,
    this.data,
    this.sourceType,
    this.sourceId,
  });

  factory CreateNotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNotificationRequestToJson(this);
}

@JsonSerializable()
class MarkAllReadResponse {
  @JsonKey(name: 'updatedCount')
  final int updatedCount;

  const MarkAllReadResponse({required this.updatedCount});

  factory MarkAllReadResponse.fromJson(Map<String, dynamic> json) =>
      _$MarkAllReadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MarkAllReadResponseToJson(this);
}

@JsonSerializable()
class DeleteAllNotificationsResponse {
  @JsonKey(name: 'deletedCount')
  final int deletedCount;

  const DeleteAllNotificationsResponse({required this.deletedCount});

  factory DeleteAllNotificationsResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteAllNotificationsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteAllNotificationsResponseToJson(this);
}

@JsonSerializable()
class DeleteNotificationResponse {
  final bool deleted;

  const DeleteNotificationResponse({required this.deleted});

  factory DeleteNotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteNotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteNotificationResponseToJson(this);
}
