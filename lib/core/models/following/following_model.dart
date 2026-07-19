import '../user/user_model.dart';
import '../user_field_instance.dart';

/// Backend `Following` edge (`/followings/*` payloads).
///
/// [requester] / [recipient] may be a raw id `String` or a populated
/// [UserModel], mirroring how the API populates them.
class FollowingModel {
  final String? id;
  final dynamic requester;
  final dynamic recipient;
  final String? recipientType;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  FollowingModel({
    this.id,
    this.requester,
    this.recipient,
    this.recipientType,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory FollowingModel.fromJson(Map<String, dynamic> json) {
    return FollowingModel(
      id: json['_id'] as String?,
      requester: _parseUserField(json['requester']),
      recipient: _parseUserField(json['recipient']),
      recipientType: json['recipientType'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  static dynamic _parseUserField(Object? raw) {
    if (raw is Map<String, dynamic>) return UserModel.fromJson(raw);
    if (raw is String) return raw;
    return null;
  }

  UserFieldInstance? _requesterHelper;
  UserFieldInstance get requesterHelper {
    _requesterHelper ??= UserFieldInstance(requester);
    return _requesterHelper!;
  }

  UserFieldInstance? _recipientHelper;
  UserFieldInstance get recipientHelper {
    _recipientHelper ??= UserFieldInstance(recipient);
    return _recipientHelper!;
  }

  bool get isAccepted => status == 'accepted';
}
