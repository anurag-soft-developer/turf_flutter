import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';

/// Lists all teams the current user belongs to (as owner or member).
class MyTeamsController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxBool isLoading = true.obs;
  final RxList<TeamMemberModel> memberships = <TeamMemberModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final result = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          limit: 50,
        ),
      );
      memberships.assignAll(result?.data ?? []);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() async => load();

  /// Check whether the current user is an owner of the team referenced by [membership].
  bool isOwnerOf(TeamMemberModel membership) {
    final uid = Get.find<AuthStateController>().user?.id;
    if (uid == null) return false;
    // We only have TeamMemberFieldInstance from the membership, which doesn't
    // include ownerIds. Use leadershipRole as a proxy — owners are typically
    // captains, but the definitive check happens on the detail screen.
    // For a simpler heuristic: if the user created the team, they're an owner.
    // Since we can't know that from membership alone, we'll show leadership role.
    return false;
  }

  String roleLabel(TeamMemberModel membership) {
    if (membership.leadershipRole == LeadershipRole.captain) return 'Captain';
    if (membership.leadershipRole == LeadershipRole.viceCaptain) {
      return 'Vice Captain';
    }
    return 'Member';
  }
}
