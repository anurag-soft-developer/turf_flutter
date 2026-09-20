import 'package:get/get.dart';

import '../../team/members/model/team_member_model.dart';
import '../model/team_match_model.dart';

/// Shared memberships + team picker used by Challenges and My Matches.
class MatchTeamFilterController extends GetxController {
  final RxList<TeamMemberModel> memberships = <TeamMemberModel>[].obs;
  final RxBool filterAllTeams = true.obs;
  final Rxn<TeamMemberFieldInstance> selectedMembershipTeam =
      Rxn<TeamMemberFieldInstance>();

  List<TeamMemberFieldInstance> get myTeams {
    final list = <TeamMemberFieldInstance>[];
    for (final m in memberships) {
      final t = m.team;
      if (t is TeamMemberFieldInstance && t.id != null && t.id!.isNotEmpty) {
        list.add(t);
      }
    }
    final seen = <String>{};
    return list.where((t) => seen.add(t.id!)).toList();
  }

  String get teamFilterKey {
    if (filterAllTeams.value) return 'all';
    return selectedMembershipTeam.value?.id ?? 'all';
  }

  String? get selectedTeamIdOrNull {
    if (filterAllTeams.value) return null;
    return selectedMembershipTeam.value?.id;
  }

  /// Team ids for list endpoints: one selected team or all distinct [myTeams] ids.
  List<String> activeTeamIdsForList() {
    if (!filterAllTeams.value) {
      final tid = selectedMembershipTeam.value?.id;
      if (tid == null || tid.isEmpty) return <String>[];
      return <String>[tid];
    }
    final ids = <String>[];
    final seen = <String>{};
    for (final t in myTeams) {
      final tid = t.id;
      if (tid == null || tid.isEmpty) continue;
      if (seen.add(tid)) ids.add(tid);
    }
    return ids;
  }

  void syncMemberships(List<TeamMemberModel> data) {
    memberships.assignAll(data);
    if (!filterAllTeams.value) {
      final sel = selectedMembershipTeam.value;
      if (sel != null && !myTeams.any((t) => t.id == sel.id)) {
        selectedMembershipTeam.value = myTeams.isNotEmpty
            ? myTeams.first
            : null;
      }
    }
  }

  void selectTeamForFilter(TeamMemberFieldInstance team) {
    filterAllTeams.value = false;
    selectedMembershipTeam.value = team;
  }

  void selectAllTeamsFilter() {
    filterAllTeams.value = true;
  }

  bool isIncomingForMatch(TeamMatchModel match) {
    final toId = match.toTeamHelper.getId();
    final fromId = match.fromTeamHelper.getId();
    if (!filterAllTeams.value) {
      final sel = selectedMembershipTeam.value?.id;
      if (sel != null) {
        if (sel == toId) return true;
        if (sel == fromId) return false;
      }
    }
    final myIds = <String>{};
    for (final t in myTeams) {
      if (t.id != null && t.id!.isNotEmpty) myIds.add(t.id!);
    }
    final onTo = toId != null && myIds.contains(toId);
    final onFrom = fromId != null && myIds.contains(fromId);
    if (onTo && !onFrom) return true;
    if (onFrom && !onTo) return false;
    if (onTo) return true;
    return false;
  }
}

T? enumTabFromArguments<T extends Enum>(Iterable<T> values) {
  final raw = Get.arguments;
  if (raw is! Map) return null;
  final tabName = raw['tab'];
  if (tabName is! String) return null;
  for (final tab in values) {
    if (tab.name == tabName) return tab;
  }
  return null;
}
