import '../../../core/models/team/team_member_field_instance.dart';
import '../../../core/models/user/user_model.dart';
import '../../../core/models/user_field_instance.dart';

/// Backend [TeamInviteStatus].
enum TeamInviteStatus {
  pending,
  accepted,
  rejected,
  expired,
  revoked,
}

/// Query for team invites / my invitations list endpoints.
class TeamInviteFilterQuery {
  final TeamInviteStatus? status;
  final int page;
  final int limit;

  const TeamInviteFilterQuery({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) params['status'] = status!.name;
    return params;
  }
}

class CreateTeamInviteRequest {
  final String? email;
  final String? phone;

  const CreateTeamInviteRequest({this.email, this.phone})
      : assert(
          (email != null) != (phone != null),
          'Provide exactly one of email or phone',
        );

  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
}

class TeamInviteModel {
  final String? id;
  final dynamic team;
  final dynamic invitedBy;
  final dynamic inviteeUser;
  final String? email;
  final String? phone;
  final TeamInviteStatus status;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final DateTime? createdAt;

  const TeamInviteModel({
    this.id,
    this.team,
    this.invitedBy,
    this.inviteeUser,
    this.email,
    this.phone,
    required this.status,
    this.expiresAt,
    this.respondedAt,
    this.createdAt,
  });

  String? get teamId {
    if (team is String) return team as String;
    if (team is TeamMemberFieldInstance) return (team as TeamMemberFieldInstance).id;
    if (team is Map) {
      final m = team as Map;
      return (m['_id'] ?? m['id'])?.toString();
    }
    return null;
  }

  String get teamName {
    if (team is TeamMemberFieldInstance) {
      return (team as TeamMemberFieldInstance).name;
    }
    if (team is Map) {
      return (team as Map)['name']?.toString() ?? 'Team';
    }
    return 'Team';
  }

  String? get teamLogo {
    if (team is TeamMemberFieldInstance) {
      final logo = (team as TeamMemberFieldInstance).logo;
      return logo.isNotEmpty ? logo : null;
    }
    if (team is Map) {
      final logo = (team as Map)['logo']?.toString();
      return (logo != null && logo.isNotEmpty) ? logo : null;
    }
    return null;
  }

  UserFieldInstance get invitedByHelper => UserFieldInstance(invitedBy);
  UserFieldInstance get inviteeHelper => UserFieldInstance(inviteeUser);

  String get contactLabel {
    if (email != null && email!.isNotEmpty) return email!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    final name = inviteeHelper.getDisplayName();
    if (name != 'Unknown User') return name;
    return 'Unknown contact';
  }

  factory TeamInviteModel.fromJson(Map<String, dynamic> json) {
    return TeamInviteModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      team: _parseTeam(json['team']),
      invitedBy: _parseUser(json['invitedBy']),
      inviteeUser: _parseUser(json['inviteeUser']),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: _parseStatus(json['status']),
      expiresAt: _parseDate(json['expiresAt']),
      respondedAt: _parseDate(json['respondedAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static dynamic _parseTeam(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map<String, dynamic>) {
      try {
        return TeamMemberFieldInstance.fromJson(raw);
      } catch (_) {
        return raw;
      }
    }
    if (raw is Map) {
      return _parseTeam(Map<String, dynamic>.from(raw));
    }
    return raw;
  }

  static dynamic _parseUser(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map<String, dynamic>) {
      try {
        return UserModel.fromJson(raw);
      } catch (_) {
        return raw;
      }
    }
    if (raw is Map) {
      return _parseUser(Map<String, dynamic>.from(raw));
    }
    return raw;
  }

  static TeamInviteStatus _parseStatus(dynamic raw) {
    final s = raw?.toString() ?? 'pending';
    return TeamInviteStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TeamInviteStatus.pending,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}
