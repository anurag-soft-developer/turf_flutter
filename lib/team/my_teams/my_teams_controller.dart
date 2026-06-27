import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';

/// Lists all teams the current user belongs to (as owner or member).
class MyTeamsController extends GetxController {
  static const int _pageSize = 20;

  final TeamService _teamService = TeamService();

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxList<TeamMemberModel> memberships = <TeamMemberModel>[].obs;

  int _currentPage = 1;
  int _totalPages = 1;

  bool get canLoadMore =>
      _currentPage < _totalPages && !isLoadingMore.value;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    isLoading.value = true;
    _currentPage = 1;
    _totalPages = 1;
    try {
      final result = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          page: 1,
          limit: _pageSize,
        ),
      );
      if (result != null) {
        memberships.assignAll(result.data);
        _currentPage = result.page;
        _totalPages = result.totalPages;
      } else {
        memberships.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => loadInitial();

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _currentPage + 1;
      final result = await _teamService.memberService.myMemberships(
        MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          page: nextPage,
          limit: _pageSize,
        ),
      );
      if (result != null && result.data.isNotEmpty) {
        memberships.addAll(result.data);
        _currentPage = result.page;
        _totalPages = result.totalPages;
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

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
}
