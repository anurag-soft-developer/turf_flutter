// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_query_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportReplyModel _$SupportReplyModelFromJson(Map<String, dynamic> json) =>
    SupportReplyModel(
      id: json['_id'] as String?,
      authorId: const UserConverter().fromJson(json['authorId']),
      authorRole: json['authorRole'] as String,
      body: json['body'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$SupportReplyModelToJson(SupportReplyModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'authorId': const UserConverter().toJson(instance.authorId),
      'authorRole': instance.authorRole,
      'body': instance.body,
      'createdAt': instance.createdAt,
    };

SupportQueryModel _$SupportQueryModelFromJson(Map<String, dynamic> json) =>
    SupportQueryModel(
      id: json['_id'] as String,
      userId: const UserConverter().fromJson(json['userId']),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map(
                (e) => SupportReplyModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$SupportQueryModelToJson(SupportQueryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userId': const UserConverter().toJson(instance.userId),
      'email': instance.email,
      'phone': instance.phone,
      'subject': instance.subject,
      'message': instance.message,
      'status': instance.status,
      'replies': instance.replies.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
