import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../components/match_up/team_logo.dart';
import '../components/shared/app_network_image.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/components/scroll/pinned_sliver_header.dart';
import '../core/config/constants.dart';
import '../core/models/paginated_response.dart';
import '../core/models/team/team_member_field_instance.dart';
import '../core/query/query_keys.dart';
import '../core/query/query_retry.dart';
import '../core/utils/app_snackbar.dart';
import '../team/model/team_model.dart';
import '../team/utils/team_ui.dart';
import 'model/enrollment_model.dart';
import 'model/opening_model.dart';
import 'opening_manage.dart';
import 'opening_service.dart';
import 'openings_controller.dart';

class OpeningsScreen extends HookWidget {
  const OpeningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OpeningsController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: Obx(() {
        final sport = controller.selectedSport.value;
        final type = controller.selectedType.value;
        return _OpeningsFeed(
          key: ValueKey('${type?.name ?? 'all'}|${sport?.name ?? 'all'}'),
          controller: controller,
          sport: sport,
          type: type,
        );
      }),
    );
  }
}

class _OpeningsFeed extends HookWidget {
  const _OpeningsFeed({
    super.key,
    required this.controller,
    required this.sport,
    required this.type,
  });

  final OpeningsController controller;
  final TeamSportType? sport;
  final OpeningType? type;

  @override
  Widget build(BuildContext context) {
    final query =
        useInfiniteQuery<PaginatedResponse<OpeningModel>, Object, int>(
          QueryKeys.openings(sport: sport?.name, type: type?.name),
          (ctx) async {
            final result = await OpeningService().findMany(
              OpeningFilterQuery(
                type: type,
                sportType: sport?.name,
                status: OpeningStatus.open,
                page: ctx.pageParam,
                limit: 20,
              ),
            );
            return result ?? EmptyPaginatedResponse<OpeningModel>();
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
        const <OpeningModel>[];

    return RefreshIndicator(
      edgeOffset: floatingRefreshEdgeOffset(context),
      onRefresh: () async {
        await query.refetch();
      },
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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            FloatingSliverAppBar(
              title: const Text('Openings'),
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'openings') {
                      Get.toNamed(AppConstants.routes.myOpenings);
                    } else if (value == 'requests') {
                      Get.toNamed(AppConstants.routes.myJoinRequests);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'openings',
                      child: Text('My openings'),
                    ),
                    PopupMenuItem(
                      value: 'requests',
                      child: Text('My requests'),
                    ),
                  ],
                ),
              ],
            ),
            PinnedSliverHeader(
              child: OpeningFiltersBar(
                sport: sport,
                type: type,
                onSportChanged: controller.switchSport,
                onTypeChanged: controller.switchType,
              ),
            ),
            ..._feedSlivers(query, items),
          ],
        ),
      ),
    );
  }

  List<Widget> _feedSlivers(
    InfiniteQueryResult<PaginatedResponse<OpeningModel>, Object, int> query,
    List<OpeningModel> items,
  ) {
    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return [
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
      ];
    }

    if (query.isError && items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 42,
                  color: Color(AppColors.textSecondaryColor),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Failed to load openings',
                  style: TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => query.refetch(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.group_add_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  sport == null && type == null
                      ? 'No openings yet.'
                      : 'No openings match these filters.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
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
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
              child: Obx(() {
                controller.enrollingIds.length;
                final opening = items[index];
                return _OpeningCard(opening: opening, controller: controller);
              }),
            );
          }, childCount: items.length + (query.isFetchingNextPage ? 1 : 0)),
        ),
      ),
    ];
  }
}

class _OpeningCard extends StatelessWidget {
  const _OpeningCard({required this.opening, required this.controller});

  final OpeningModel opening;
  final OpeningsController controller;

  @override
  Widget build(BuildContext context) {
    final sport = _sportOf(opening.sportType);
    final place = opening.hostPlace?.trim();
    final meta = [
      if (opening.type == OpeningType.tournament) 'Tournament',
      if (sport != null) teamSportLabel(sport),
      if (place != null && place.isNotEmpty) place,
    ].join(' · ');
    final showEnroll = _canEnroll(opening);

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openHost,
        child: opening.type == OpeningType.tournament
            ? _tournamentBody(sport, meta, showEnroll)
            : _teamBody(meta, showEnroll),
      ),
    );
  }

  Widget _teamBody(String meta, bool showEnroll) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeamLogo(
                url: opening.hostImage ?? '',
                size: 48,
                teamId: opening.hostId,
              ),
              const SizedBox(width: 12),
              Expanded(child: _copy(meta)),
            ],
          ),
          if (showEnroll) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _OpeningAction(opening: opening, controller: controller),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tournamentBody(TeamSportType? sport, String meta, bool showEnroll) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 112),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _copy(meta),
                  if (showEnroll) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _OpeningAction(
                        opening: opening,
                        controller: controller,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 112,
            child: _OpeningCover(imageUrl: opening.hostImage, sport: sport),
          ),
        ],
      ),
    );
  }

  Widget _copy(String meta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          opening.title,
          style: const TextStyle(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          opening.hostName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            meta,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
        ],
      ],
    );
  }

  void _openHost() {
    switch (opening.type) {
      case OpeningType.team:
        if (opening.hostId.isEmpty) return;
        Get.toNamed(
          AppConstants.routes.teamProfile,
          arguments: {'teamId': opening.hostId},
        );
      case OpeningType.tournament:
        if (opening.hostId.isEmpty) return;
        Get.toNamed(AppConstants.routes.tournamentDetail(opening.hostId));
    }
  }
}

bool _canEnroll(OpeningModel opening) {
  final me = Get.isRegistered<AuthStateController>()
      ? Get.find<AuthStateController>().user?.id
      : null;
  if (me == null || me.isEmpty || me == opening.postedBy) return false;
  final mine = opening.myStatus;
  if (mine == EnrollmentStatus.pending || mine == EnrollmentStatus.accepted) {
    return false;
  }
  final openingId = opening.id;
  return openingId != null && openingId.isNotEmpty;
}

class _OpeningCover extends StatelessWidget {
  const _OpeningCover({required this.imageUrl, this.sport});

  final String? imageUrl;
  final TeamSportType? sport;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final primary = const Color(AppColors.primaryColor);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isEmpty)
          _placeholder(primary)
        else
          AppNetworkImage(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _placeholder(primary),
          ),
      ],
    );
  }

  Widget _placeholder(Color primary) {
    return ColoredBox(
      color: primary.withValues(alpha: 0.06),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.18),
              primary.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            sport?.icon ?? Icons.emoji_events_outlined,
            size: 36,
            color: primary.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _OpeningAction extends StatelessWidget {
  const _OpeningAction({required this.opening, required this.controller});

  final OpeningModel opening;
  final OpeningsController controller;

  @override
  Widget build(BuildContext context) {
    if (!_canEnroll(opening)) return const SizedBox.shrink();
    final openingId = opening.id!;
    final enrolling = controller.enrollingIds.contains(openingId);
    return _ActionButton(
      label: 'Enroll',
      isLoading: enrolling,
      onPressed: () => _enroll(context),
    );
  }

  Future<void> _enroll(BuildContext context) async {
    if (opening.type == OpeningType.team) {
      await controller.enroll(opening);
      return;
    }
    final teams = await controller.enterableTeams(opening.sportType);
    if (!context.mounted) return;
    if (teams.isEmpty) {
      AppSnackbar.warning(
        title: 'No team to enter',
        message:
            'You need to be an owner, captain, or vice captain of a team in this sport.',
      );
      return;
    }
    if (teams.length == 1) {
      await controller.enroll(opening, teamId: teams.first.id);
      return;
    }
    final picked = await showModalBottomSheet<TeamMemberFieldInstance>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TeamPickSheet(teams: teams),
    );
    if (picked?.id == null) return;
    await controller.enroll(opening, teamId: picked!.id);
  }
}

class _TeamPickSheet extends StatelessWidget {
  const _TeamPickSheet({required this.teams});

  final List<TeamMemberFieldInstance> teams;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Enter with',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(AppColors.textColor),
              ),
            ),
          ),
          for (final team in teams)
            ListTile(
              title: Text(team.name),
              onTap: () => Navigator.of(context).pop(team),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final buttonColor = const Color(AppColors.primaryColor);
    return FilledButton(
      onPressed: onPressed == null || isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: buttonColor.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              softWrap: false,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}

TeamSportType? _sportOf(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final sport in TeamSportType.values) {
    if (sport.name == raw) return sport;
  }
  return null;
}
