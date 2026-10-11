import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../components/tournaments/tournament_entry_tile.dart';
import '../../components/tournaments/tournament_invite_team_sheet.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../model/tournament_models.dart';
import 'tournament_detail_controller.dart';

class TournamentEntriesScreen extends HookWidget {
  const TournamentEntriesScreen({super.key});

  static const _tabs = [
    AppTabItem(label: 'All'),
    AppTabItem(label: 'Sent'),
    AppTabItem(label: 'Received'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TournamentDetailController>();
    final ticker = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: _tabs.length, vsync: ticker),
      [ticker],
    );

    useEffect(() {
      controller.loadInvitations();
      return () => tabController.dispose();
    }, [tabController]);

    return Obx(() {
      final showFab = controller.isOrganizer &&
          controller.tournament.value?.status == 'inviting' &&
          !controller.isRosterLocked;

      return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(
        title: Obx(
          () => Text(
            controller.tournament.value?.name == null
                ? 'Teams & invites'
                : 'Teams · ${controller.tournament.value!.name}',
          ),
        ),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => showTournamentInviteTeamSheet(
                context,
                controller: controller,
              ),
              backgroundColor: const Color(AppColors.primaryColor),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Invite'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSegmentedTabs(
            controller: tabController,
            items: _tabs,
            fillWidth: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          ),
          Expanded(
            child: AppSegmentedTabView(
              controller: tabController,
              children: [
                _EntriesList(filter: _EntryFilter.all),
                _EntriesList(filter: _EntryFilter.sent),
                _EntriesList(filter: _EntryFilter.received),
              ],
            ),
          ),
        ],
      ),
    );
    });
  }
}

enum _EntryFilter { all, sent, received }

class _EntriesList extends GetView<TournamentDetailController> {
  const _EntriesList({required this.filter});

  final _EntryFilter filter;

  List<TournamentEntryModel> _items() {
    final all = controller.visibleEntries;
    final organizer = controller.isOrganizer;
    return switch (filter) {
      _EntryFilter.all => all,
      _EntryFilter.sent => all.where((entry) {
        if (organizer) {
          return entry.direction == 'invite';
        }
        return entry.direction == 'request' && controller.isMyTeamEntry(entry);
      }).toList(),
      _EntryFilter.received => all.where((entry) {
        if (organizer) {
          return entry.direction == 'request';
        }
        return entry.direction == 'invite' && controller.isMyTeamEntry(entry);
      }).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = _items();
      final emptyMessage = switch (filter) {
        _EntryFilter.all => 'No entries yet.',
        _EntryFilter.sent => controller.isOrganizer
            ? 'No invites sent.'
            : 'No join requests sent.',
        _EntryFilter.received => controller.isOrganizer
            ? 'No join requests.'
            : 'No invites received.',
      };
      if (items.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.loadInvitations,
          color: const Color(AppColors.primaryColor),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.4,
                child: Center(child: Text(emptyMessage)),
              ),
            ],
          ),
        );
      }
      final totalLabel = items.length == 1 ? '1 team' : '${items.length} teams';
      return RefreshIndicator(
        onRefresh: controller.loadInvitations,
        color: const Color(AppColors.primaryColor),
        child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              totalLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            );
          }
          final entry = items[index - 1];
          return TournamentEntryTile(
            entry: entry,
            onRemoveAccepted: (e) => _confirmRemove(context, e),
            onWithdrawRequest: (e) => _confirmWithdrawRequest(context, e),
            onCancelInvite: (e) => _confirmCancelInvite(context, e),
          );
        },
        ),
      );
    });
  }

  Future<void> _confirmRemove(
    BuildContext context,
    TournamentEntryModel entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${entry.teamName}?'),
        content: const Text(
          'They can be invited again before you lock the lineup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.removeAcceptedTeam(entry.id);
    }
  }

  Future<void> _confirmWithdrawRequest(
    BuildContext context,
    TournamentEntryModel entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw request?'),
        content: Text(
          'Remove ${entry.teamName}\'s join request from this tournament.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.withdrawRequest(entry.id);
    }
  }

  Future<void> _confirmCancelInvite(
    BuildContext context,
    TournamentEntryModel entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke invite?'),
        content: Text('Revoke the invite sent to ${entry.teamName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke invite'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.revokeInvite(entry.id);
    }
  }
}
