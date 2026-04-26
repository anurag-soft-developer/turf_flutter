import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../members/model/team_member_model.dart';
import '../utils/team_ui.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import 'my_join_requests_controller.dart';

class MyJoinRequestsScreen extends StatefulWidget {
  const MyJoinRequestsScreen({super.key});

  @override
  State<MyJoinRequestsScreen> createState() => _MyJoinRequestsScreenState();
}

class _MyJoinRequestsScreenState extends State<MyJoinRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _tabs = JoinRequestStatusTab.values;

  @override
  void initState() {
    super.initState();
    final c = Get.find<MyJoinRequestsController>();
    final idx = _tabs.indexOf(c.selectedTab.value);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: idx < 0 ? 0 : idx,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final i = _tabController.index;
      if (i >= 0 && i < _tabs.length) c.switchTab(_tabs[i]);
    });
    c.ensureTabLoaded(c.selectedTab.value);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MyJoinRequestsController>();
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Join requests'),
        actions: [
          IconButton(
            tooltip: 'Find teams',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed(AppConstants.routes.teamOpenings),
          ),
        ],
      ),
      body: Obx(() {
        final i = _tabs.indexOf(c.selectedTab.value);
        if (i >= 0 && _tabController.index != i) {
          _tabController.animateTo(i);
        }
        return Column(
          children: [
            AppSegmentedTabs(
              controller: _tabController,
              onTap: (index) => c.switchTab(_tabs[index]),
              items: const [
                AppTabItem(
                  label: 'Pending',
                  icon: Icons.hourglass_top_outlined,
                ),
                AppTabItem(label: 'Joined', icon: Icons.check_circle_outline),
                AppTabItem(label: 'Rejected', icon: Icons.cancel_outlined),
              ],
            ),
            Expanded(
              child: AppSegmentedTabView(
                controller: _tabController,
                children: _tabs
                    .map((tab) => _RequestTabList(controller: c, tab: tab))
                    .toList(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RequestTabList extends StatelessWidget {
  const _RequestTabList({required this.controller, required this.tab});

  final MyJoinRequestsController controller;
  final JoinRequestStatusTab tab;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.stateFor(tab);
      // Ensure Obx subscribes to tab cache
      controller.tabStateList;

      final isFirstLoad = !state.hasInitialized && state.items.isEmpty;
      if (isFirstLoad || (state.isFetching && state.items.isEmpty)) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(AppColors.primaryColor),
            ),
          ),
        );
      }

      if (state.error != null && state.items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Color(AppColors.textSecondaryColor),
              ),
              const SizedBox(height: 10),
              Text(
                state.error!,
                style: const TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => controller.reloadTab(tab),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (state.items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _emptyMessage(tab),
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
        onRefresh: () => controller.reloadTab(tab),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _MembershipRow(membership: state.items[i]),
        ),
      );
    });
  }

  String _emptyMessage(JoinRequestStatusTab t) {
    return switch (t) {
      JoinRequestStatusTab.pending => 'No pending join requests.',
      JoinRequestStatusTab.accepted =>
        'No active team memberships in this list.',
      JoinRequestStatusTab.rejected => 'No rejected join requests.',
    };
  }
}

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({required this.membership});

  final TeamMemberModel membership;

  @override
  Widget build(BuildContext context) {
    final teamRef = membership.team;
    String teamName = 'Team';
    String? logo;
    TeamSportType? sport;
    String? teamId = membership.teamId;

    if (teamRef is TeamMemberFieldInstance) {
      teamName = teamRef.name;
      logo = teamRef.logo.isNotEmpty ? teamRef.logo : null;
      sport = teamRef.sportType;
    }

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: teamId == null || teamId.isEmpty
            ? null
            : () => Get.toNamed(
                AppConstants.routes.teamProfile,
                arguments: {'teamId': teamId},
              ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: logo != null
              ? Image.network(
                  logo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initials(teamName),
                )
              : _initials(teamName),
        ),
        title: Text(
          teamName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textColor),
          ),
        ),
        subtitle: sport != null
            ? Text(
                teamSportLabel(sport),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(membership.status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            teamMemberStatusLabel(membership.status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _statusColor(membership.status),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final s = parts.isEmpty
        ? '?'
        : (parts.length == 1
              ? (parts[0].isNotEmpty ? parts[0][0] : '?')
              : '${parts[0][0]}${parts[1][0]}');
    return Center(
      child: Text(
        s.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(AppColors.primaryColor),
        ),
      ),
    );
  }

  Color _statusColor(TeamMemberStatus s) {
    return switch (s) {
      TeamMemberStatus.pending => const Color(0xFFF9A825),
      TeamMemberStatus.active => const Color(0xFF2E7D32),
      TeamMemberStatus.rejected => const Color(0xFFC62828),
      _ => const Color(AppColors.textSecondaryColor),
    };
  }
}
