import 'team_member_field_instance.dart';

/// Helper for team ref JSON: [String] id or populated [TeamMemberFieldInstance]
/// (e.g. matchmaking `fromTeam` / `toTeam` / `winnerTeam`).
class TeamRefFieldInstance {
  final dynamic _team;

  TeamRefFieldInstance(this._team);

  String? getId() {
    if (_team is String) return _team;
    if (_team is TeamMemberFieldInstance) return _team.id;
    return null;
  }

  TeamMemberFieldInstance? getSubsetModel() {
    if (_team is TeamMemberFieldInstance) return _team;
    return null;
  }

  String? getName() {
    if (_team is TeamMemberFieldInstance) return _team.name;
    return null;
  }

  String getDisplayName() {
    final name = getName();
    if (name != null) return name;
    final id = getId();
    return id != null ? 'Team $id' : 'Unknown team';
  }

  bool get isPopulated => _team is TeamMemberFieldInstance;

  bool get isIdOnly => _team is String;
}
