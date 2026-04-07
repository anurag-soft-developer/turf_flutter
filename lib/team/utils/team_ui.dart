import '../model/team_model.dart';
import '../members/model/team_member_model.dart';

String teamSportLabel(TeamSportType type) {
  switch (type) {
    case TeamSportType.cricket:
      return 'Cricket';
    case TeamSportType.football:
      return 'Football';
  }
}

String teamVisibilityLabel(TeamVisibility v) {
  switch (v) {
    case TeamVisibility.public:
      return 'Public';
    case TeamVisibility.private:
      return 'Private';
  }
}

String teamJoinModeLabel(TeamJoinMode m) {
  switch (m) {
    case TeamJoinMode.open:
      return 'Open join';
    case TeamJoinMode.approval:
      return 'Approval required';
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
