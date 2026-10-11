import '../../core/models/user/user_model.dart';
import '../../core/models/user_field_instance.dart';

enum InvitationKind { teamInvite, tournamentInvite }

enum InvitationStatus {
  pending,
  accepted,
  declined,
  revoked,
  withdrawn,
  expired,
}

/// Shared shape for `kind: teamInvite | tournamentInvite` documents.
class InvitationModel {
  final String id;
  final InvitationKind? kind;
  final InvitationStatus status;
  final String? teamId;
  final String teamName;
  final String? teamLogo;
  final String? tournamentId;
  final String? tournamentName;
  final String? direction;
  final String inviterName;
  final String? email;
  final String? phone;
  final dynamic inviteeUser;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const InvitationModel({
    required this.id,
    required this.status,
    this.kind,
    this.teamId,
    this.teamName = 'Team',
    this.teamLogo,
    this.tournamentId,
    this.tournamentName,
    this.direction,
    this.inviterName = 'Someone',
    this.email,
    this.phone,
    this.inviteeUser,
    this.expiresAt,
    this.createdAt,
  });

  UserFieldInstance get invitee => UserFieldInstance(inviteeUser);

  String? get inviteeId => invitee.getId();

  String get contactLabel {
    final name = invitee.getDisplayName();
    if (invitee.isPopulated && name != 'Unknown User') return name;
    if (email != null && email!.isNotEmpty) return email!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    if (name != 'Unknown User') return name;
    return 'Unknown contact';
  }

  bool get isTournament => kind == InvitationKind.tournamentInvite;

  String get title =>
      isTournament ? (tournamentName ?? 'Tournament') : teamName;

  String get subtitle => isTournament
      ? '$teamName was invited to play'
      : 'Invited by $inviterName';

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'];
    final tournament = json['tournament'];
    return InvitationModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      kind: invitationKindFromJson(json['kind']),
      status: invitationStatusFromJson(json['status']),
      teamId: _refId(team),
      teamName: _name(team) ?? 'Team',
      teamLogo: _logo(team),
      tournamentId: _refId(tournament),
      tournamentName: _name(tournament),
      direction: json['direction']?.toString(),
      inviterName:
          UserFieldInstance(_parseUser(json['invitedBy'])).getDisplayName(),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      inviteeUser: _parseUser(json['inviteeUser']),
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

InvitationStatus invitationStatusFromJson(dynamic raw) {
  final value = raw?.toString() ?? 'pending';
  return InvitationStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => InvitationStatus.pending,
  );
}

InvitationKind? invitationKindFromJson(dynamic raw) {
  final value = raw?.toString();
  if (value == null || value.isEmpty) return null;
  for (final kind in InvitationKind.values) {
    if (kind.name == value) return kind;
  }
  return null;
}

String? _refId(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is Map) {
    return (raw['_id'] ?? raw['id'])?.toString();
  }
  return raw.toString();
}

String? _name(dynamic raw) {
  if (raw is! Map) return null;
  final name = raw['name']?.toString().trim();
  if (name == null || name.isEmpty) return null;
  return name;
}

String? _logo(dynamic raw) {
  if (raw is! Map) return null;
  final logo = raw['logo']?.toString().trim();
  if (logo == null || logo.isEmpty) return null;
  return logo;
}

dynamic _parseUser(dynamic raw) {
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

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw.toString());
}
