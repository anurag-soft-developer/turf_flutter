import '../model/team_model.dart';
import '../members/model/team_member_model.dart';

String teamSportLabel(TeamSportType type) => type.label;

String teamVisibilityLabel(TeamVisibility v) {
  switch (v) {
    case TeamVisibility.public:
      return 'Public';
    case TeamVisibility.private:
      return 'Private';
  }
}

String teamMemberStatusLabel(TeamMemberStatus s) {
  switch (s) {
    case TeamMemberStatus.pending:
      return 'Pending';
    case TeamMemberStatus.active:
      return 'Active';
    case TeamMemberStatus.resigned:
      return 'Resigned';
    case TeamMemberStatus.removed:
      return 'Removed';
    case TeamMemberStatus.rejected:
      return 'Rejected';
    case TeamMemberStatus.suspended:
      return 'Suspended';
  }
}

String leadershipRoleLabel(LeadershipRole? r) {
  if (r == null) return '';
  switch (r) {
    case LeadershipRole.captain:
      return 'Captain';
    case LeadershipRole.viceCaptain:
      return 'Vice captain';
  }
}
