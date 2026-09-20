import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/match_up/my_team_selector.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/components/scroll/floating_sliver_app_bar.dart';
import '../../core/components/scroll/pinned_sliver_header.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/team_service.dart';
import 'match_team_filter_controller.dart';

/// App bar + memberships + team filter + segmented tabs for match lists.
class MatchListScaffold extends HookWidget {
  const MatchListScaffold({
    super.key,
    required this.title,
    required this.teamSheetTitle,
    required this.emptyTeamsMessage,
    required this.controller,
    required this.tabs,
    required this.initialTabIndex,
    required this.onTabChanged,
    required this.buildPanes,
  });

  final String title;
  final String teamSheetTitle;
  final String emptyTeamsMessage;
  final MatchTeamFilterController controller;
  final List<AppTabItem> tabs;
  final int initialTabIndex;
  final ValueChanged<int> onTabChanged;
  final List<Widget> Function(String filterKey) buildPanes;

  @override
  Widget build(BuildContext context) {
    final teamService = TeamService();
    final ticker = useSingleTickerProvider();

    final membershipsQuery = useQuery<List<TeamMemberModel>, Object>(
      QueryKeys.myMemberships,
      (_) async {
        final res = await teamService.memberService.myMemberships(
          const MyTeamMembershipsFilterQuery(
            status: TeamMemberStatus.active,
            limit: 50,
          ),
        );
        return res?.data ?? const <TeamMemberModel>[];
      },
      retry: noRetry,
    );

    useEffect(() {
      final data = membershipsQuery.data;
      if (data != null) {
        controller.syncMemberships(data);
      }
      return null;
    }, [membershipsQuery.data]);

    final safeInitial = initialTabIndex.clamp(0, tabs.length - 1);
    final tabController = useMemoized(
      () => TabController(
        length: tabs.length,
        vsync: ticker,
        initialIndex: safeInitial,
      ),
      [ticker],
    );

    useEffect(() {
      void listener() {
        if (tabController.indexIsChanging) return;
        onTabChanged(tabController.index);
      }

      tabController.addListener(listener);
      return () {
        tabController.removeListener(listener);
        tabController.dispose();
      };
    }, [tabController]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: _buildBody(
        membershipsQuery: membershipsQuery,
        tabController: tabController,
      ),
    );
  }

  Widget _buildBody({
    required QueryResult<List<TeamMemberModel>, Object> membershipsQuery,
    required TabController tabController,
  }) {
    if (membershipsQuery.isLoading ||
        (membershipsQuery.isFetching && membershipsQuery.data == null)) {
      return CustomScrollView(
        slivers: [
          FloatingSliverAppBar(title: Text(title)),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(AppColors.primaryColor),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (membershipsQuery.isError && membershipsQuery.data == null) {
      return CustomScrollView(
        slivers: [
          FloatingSliverAppBar(title: Text(title)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: ElevatedButton(
                onPressed: () => membershipsQuery.refetch(),
                child: const Text('Retry'),
              ),
            ),
          ),
        ],
      );
    }

    return Obx(() {
      if (controller.myTeams.isEmpty) {
        return CustomScrollView(
          slivers: [
            FloatingSliverAppBar(title: Text(title)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _NoMembershipsMessage(message: emptyTeamsMessage),
            ),
          ],
        );
      }

      final filterKey = controller.teamFilterKey;

      return NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            FloatingSliverAppBar(title: Text(title)),
            PinnedSliverHeader(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: MyTeamSelector(
                            teams: controller.myTeams,
                            allowToSelectAll: true,
                            allTeamsSelected: controller.filterAllTeams.value,
                            selectedTeam:
                                controller.selectedMembershipTeam.value,
                            sheetTitle: teamSheetTitle,
                            onTeamSelected: controller.selectTeamForFilter,
                            onAllTeamsSelected: controller.selectAllTeamsFilter,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: AppSegmentedTabs(
                      controller: tabController,
                      onTap: onTabChanged,
                      padding: EdgeInsets.zero,
                      fillWidth: true,
                      items: tabs,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: AppSegmentedTabView(
          controller: tabController,
          children: buildPanes(filterKey),
        ),
      );
    });
  }
}

class _NoMembershipsMessage extends StatelessWidget {
  const _NoMembershipsMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 56,
              color: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            const Text(
              'No teams yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
