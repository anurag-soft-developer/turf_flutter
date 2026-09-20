import 'package:json_annotation/json_annotation.dart';

import '../../core/models/user_field_converters.dart';

part 'support_query_model.g.dart';

@JsonSerializable()
class SupportReplyModel {
  @JsonKey(name: '_id')
  final String? id;

  @UserConverter()
  @JsonKey(name: 'authorId')
  final dynamic authorId;

  @JsonKey(name: 'authorRole')
  final String authorRole;

  final String body;

  @JsonKey(name: 'createdAt')
  final String createdAt;

  const SupportReplyModel({
    this.id,
    required this.authorId,
    required this.authorRole,
    required this.body,
    required this.createdAt,
  });

  factory SupportReplyModel.fromJson(Map<String, dynamic> json) =>
      _$SupportReplyModelFromJson(json);

  Map<String, dynamic> toJson() => _$SupportReplyModelToJson(this);

  bool get isPlatformAdmin => authorRole == 'platform_admin';
}

@JsonSerializable(explicitToJson: true)
class SupportQueryModel {
  @JsonKey(name: '_id')
  final String id;

  @UserConverter()
  @JsonKey(name: 'userId')
  final dynamic userId;

  final String? email;
  final String? phone;
  final String subject;
  final String message;
  final String status;
  @JsonKey(defaultValue: <SupportReplyModel>[])
  final List<SupportReplyModel> replies;

  @JsonKey(name: 'createdAt')
  final String createdAt;

  @JsonKey(name: 'updatedAt')
  final String updatedAt;

  const SupportQueryModel({
    required this.id,
    required this.userId,
    this.email,
    this.phone,
    required this.subject,
    required this.message,
    required this.status,
    required this.replies,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportQueryModel.fromJson(Map<String, dynamic> json) =>
      _$SupportQueryModelFromJson(json);

  Map<String, dynamic> toJson() => _$SupportQueryModelToJson(this);

  String get contactDisplay => email ?? phone ?? '';

  bool get isActive => status == 'open' || status == 'in_progress';

  bool get isResolved => status == 'resolved';
}

class CreateSupportQueryPayload {
  const CreateSupportQueryPayload({
    this.email,
    this.phone,
    required this.subject,
    required this.message,
  });

  final String? email;
  final String? phone;
  final String subject;
  final String message;

  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'subject': subject,
        'message': message,
      };
}
