// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['_id'] as String,
      recipientUserId: json['recipientUserId'] as String,
      module: notificationRecordModuleFromJson(json['module']),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      sourceType: json['sourceType'] as String?,
      sourceId: json['sourceId'] as String?,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'recipientUserId': instance.recipientUserId,
      'module': notificationRecordModuleToJson(instance.module),
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'sourceType': instance.sourceType,
      'sourceId': instance.sourceId,
      'readAt': instance.readAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

CreateNotificationRequest _$CreateNotificationRequestFromJson(
  Map<String, dynamic> json,
) => CreateNotificationRequest(
  recipientUserId: json['recipientUserId'] as String,
  module: notificationRecordModuleFromJson(json['module']),
  title: json['title'] as String,
  body: json['body'] as String,
  data: json['data'] as Map<String, dynamic>?,
  sourceType: json['sourceType'] as String?,
  sourceId: json['sourceId'] as String?,
);

Map<String, dynamic> _$CreateNotificationRequestToJson(
  CreateNotificationRequest instance,
) => <String, dynamic>{
  'recipientUserId': instance.recipientUserId,
  'module': notificationRecordModuleToJson(instance.module),
  'title': instance.title,
  'body': instance.body,
  'data': instance.data,
  'sourceType': instance.sourceType,
  'sourceId': instance.sourceId,
};

MarkAllReadResponse _$MarkAllReadResponseFromJson(Map<String, dynamic> json) =>
    MarkAllReadResponse(updatedCount: (json['updatedCount'] as num).toInt());

Map<String, dynamic> _$MarkAllReadResponseToJson(
  MarkAllReadResponse instance,
) => <String, dynamic>{'updatedCount': instance.updatedCount};

DeleteAllNotificationsResponse _$DeleteAllNotificationsResponseFromJson(
  Map<String, dynamic> json,
) => DeleteAllNotificationsResponse(
  deletedCount: (json['deletedCount'] as num).toInt(),
);

Map<String, dynamic> _$DeleteAllNotificationsResponseToJson(
  DeleteAllNotificationsResponse instance,
) => <String, dynamic>{'deletedCount': instance.deletedCount};

DeleteNotificationResponse _$DeleteNotificationResponseFromJson(
  Map<String, dynamic> json,
) => DeleteNotificationResponse(deleted: json['deleted'] as bool);

Map<String, dynamic> _$DeleteNotificationResponseToJson(
  DeleteNotificationResponse instance,
) => <String, dynamic>{'deleted': instance.deleted};
