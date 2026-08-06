import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../team_service.dart';
import 'model/team_invite_model.dart';
import 'my_invitations_controller.dart';

enum InvitationStatusTab { pending, accepted, rejected }

class MyInvitationsScreen extends HookWidget {
  const MyInvitationsScreen({super.key});

  static const _tabs = InvitationStatusTab.values;

  @override
  Widget build(BuildContext context) {
    final selectedTab = useState(InvitationStatusTab.pending);
    final ticker = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(
        length: _tabs.length,
        vsync: ticker,
        initialIndex: _tabs.indexOf(selectedTab.value),
      ),
      [ticker],
    );

    useEffect(() {
      void listener() {
        if (tabController.indexIsChanging) return;
        final i = tabController.index;
        if (i >= 0 && i < _tabs.length) {
          selectedTab.value = _tabs[i];
        }
      }

      tabController.addListener(listener);
      return () {
        tabController.removeListener(listener);
        tabController.dispose();
      };
    }, [tabController]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Invitations'),
      ),
      body: Column(
        children: [
          AppSegmentedTabs(
            controller: tabController,
            fillWidth: true,
            onTap: (index) {
              selectedTab.value = _tabs[index];
              tabController.animateTo(index);
            },
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            items: const [
              AppTabItem(
                label: 'Pending',
                icon: Icons.hourglass_top_outlined,
              ),
              AppTabItem(label: 'Joined', icon: Icons.check_circle_outline),
              AppTabItem(label: 'Declined', icon: Icons.cancel_outlined),
            ],
          ),
          Expanded(
            child: AppSegmentedTabView(
              controller: tabController,
              children: [
                for (final tab in _tabs)
                  _InvitationTabList(key: ValueKey(tab.name), tab: tab),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationTabList extends HookWidget {
  const _InvitationTabList({super.key, required this.tab});

  final InvitationStatusTab tab;

  TeamInviteStatus get _status => switch (tab) {
        InvitationStatusTab.pending => TeamInviteStatus.pending,
        InvitationStatusTab.accepted => TeamInviteStatus.accepted,
        InvitationStatusTab.rejected => TeamInviteStatus.rejected,
      };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyInvitationsController>();
    final query =
        useInfiniteQuery<PaginatedResponse<TeamInviteModel>, Object, int>(
      QueryKeys.myInvitations(tab.name),
      (ctx) async {
        final result = await TeamService().inviteService.listMine(
          TeamInviteFilterQuery(
            status: _status,
            page: ctx.pageParam,
            limit: 20,
          ),
        );
        return result ?? EmptyPaginatedResponse<TeamInviteModel>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final items =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <TeamInviteModel>[];

    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load invitations',
              style: TextStyle(color: Color(AppColors.textSecondaryColor)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => query.refetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            switch (tab) {
              InvitationStatusTab.pending => 'No pending invitations.',
              InvitationStatusTab.accepted => 'No accepted invitations.',
              InvitationStatusTab.rejected => 'No declined invitations.',
            },
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => query.refetch(),
      color: const Color(AppColors.primaryColor),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 160) {
            if (query.hasNextPage && !query.isFetchingNextPage) {
              query.fetchNextPage();
            }
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: items.length + (query.isFetchingNextPage ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return _InvitationRow(
              invite: items[index],
              showActions: tab == InvitationStatusTab.pending,
              controller: controller,
            );
          },
        ),
      ),
    );
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow({
    required this.invite,
    required this.showActions,
    required this.controller,
  });

  final TeamInviteModel invite;
  final bool showActions;
  final MyInvitationsController controller;

  @override
  Widget build(BuildContext context) {
    final logo = invite.teamLogo;
    final inviter = invite.invitedByHelper.getDisplayName();

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: invite.teamId == null || invite.teamId!.isEmpty
                  ? null
                  : () => Get.toNamed(
                        AppConstants.routes.teamProfile,
                        arguments: {'teamId': invite.teamId},
                      ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: logo != null
                    ? Image.network(
                        logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initials(invite.teamName),
                      )
                    : _initials(invite.teamName),
              ),
              title: Text(
                invite.teamName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              ),
              subtitle: Text(
                'Invited by $inviter',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 4),
              Obx(() {
                final busy = controller.actionInviteId.value == invite.id;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            busy ? null : () => controller.reject(invite),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            busy ? null : () => controller.accept(invite),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(AppColors.primaryColor),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Accept'),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final text = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(AppColors.primaryColor),
        ),
      ),
    );
  }
}
