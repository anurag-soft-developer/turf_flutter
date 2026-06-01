import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';

/// Status tabs for the current user’s team memberships / join flow.
enum JoinRequestStatusTab { pending, accepted, rejected }

class MyJoinRequestsController extends GetxController
    with SegmentedTabCacheController<JoinRequestStatusTab, TeamMemberModel> {
  static const int _pageSize = 20;

  final TeamService _teamService = TeamService();

  final Rx<JoinRequestStatusTab> selectedTab = JoinRequestStatusTab.pending.obs;

  @override
  List<JoinRequestStatusTab> get tabKeys => JoinRequestStatusTab.values;

  @override
  void onInit() {
    super.onInit();
    ensureTabLoaded(selectedTab.value);
  }

  void switchTab(JoinRequestStatusTab tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    ensureTabLoaded(tab);
  }

  SegmentedTabDataState<TeamMemberModel> stateFor(JoinRequestStatusTab tab) {
    return tabStateFor(tab);
  }

  Future<void> reloadTab(JoinRequestStatusTab tab) async {
    await ensureTabLoaded(tab, force: true);
  }

  Future<void> loadMore(JoinRequestStatusTab tab) => loadMoreTab(tab);

  @override
  bool get paginatedTabs => true;

  TeamMemberStatus _statusFor(JoinRequestStatusTab tab) {
    return switch (tab) {
      JoinRequestStatusTab.pending => TeamMemberStatus.pending,
      JoinRequestStatusTab.accepted => TeamMemberStatus.active,
      JoinRequestStatusTab.rejected => TeamMemberStatus.rejected,
    };
  }

  @override
  Future<List<TeamMemberModel>> fetchTabItems(JoinRequestStatusTab key) async {
    return (await fetchTabPage(key, 1)).items;
  }

  @override
  Future<SegmentedTabPageResult<TeamMemberModel>> fetchTabPage(
    JoinRequestStatusTab key,
    int page,
  ) async {
    final res = await _teamService.memberService.myMemberships(
      MyTeamMembershipsFilterQuery(
        status: _statusFor(key),
        page: page,
        limit: _pageSize,
      ),
    );
    return SegmentedTabPageResult(
      items: res?.data ?? <TeamMemberModel>[],
      page: res?.page ?? page,
      hasMore: res?.hasNextPage ?? false,
    );
  }

  @override
  String mapFetchError(Object error) {
    return 'Failed to load your join requests';
  }
}
