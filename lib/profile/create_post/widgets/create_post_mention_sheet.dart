import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:intl/intl.dart';

import '../../../components/match_up/match_pair_logos.dart';
import '../../../components/match_up/team_logo.dart';
import '../../../components/shared/app_network_image.dart';
import '../../../components/shared/app_search_field.dart';
import '../../../core/config/constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/query/query_retry.dart';
import '../../../match_up/matchmaking_service.dart';
import '../../../match_up/model/team_match_model.dart';
import '../../../team/model/team_model.dart';
import '../../../team/team_service.dart';
import '../../../team/utils/team_media_url.dart';
import '../../../turf/model/turf_model.dart';
import '../../../turf/turf_service.dart';

String? createPostTeamLogoUrl(String? raw) =>
    raw == null ? null : resolveTeamMediaUrl(raw);

TeamMatchTimeSlot? createPostMatchSlot(TeamMatchModel match) {
  final selectedId = match.selectedSlotProposalId;
  if (selectedId != null) {
    for (final slot in match.proposedSlots) {
      if (slot.proposalId == selectedId) return slot.slot;
    }
  }
  for (final slot in match.proposedSlots) {
    if (slot.status == MatchProposalStatus.accepted) return slot.slot;
  }
  if (match.proposedSlots.isNotEmpty) {
    return match.proposedSlots.first.slot;
  }
  return null;
}

String? createPostMatchScheduleLabel(TeamMatchModel match) {
  final slot = createPostMatchSlot(match);
  if (slot == null) return null;
  return DateFormat('EEE, d MMM y · h:mm a').format(slot.startTime.toLocal());
}

class CreatePostMatchPairLogos extends MatchPairLogos {
  const CreatePostMatchPairLogos({
    super.key,
    super.leftUrl,
    super.rightUrl,
    super.size = 36,
  });
}

Future<TeamModel?> showCreatePostTeamPicker(BuildContext context) {
  return _showMentionSheet<TeamModel>(
    context: context,
    title: 'Mention a team',
    hintText: 'Search teams',
    queryKeyPrefix: 'createPostMentionTeam',
    fetch: (query, page) async {
      return await TeamService().findMany(
            TeamFilterQuery(
              search: query.isEmpty ? null : query,
              status: TeamStatus.active,
              page: page,
              limit: 20,
            ),
          ) ??
          EmptyPaginatedResponse<TeamModel>();
    },
    itemBuilder: (team) => _MentionTile(
      leading: TeamLogo(
        url: createPostTeamLogoUrl(team.logo) ?? '',
        size: 40,
      ),
      title: team.name,
      subtitle: team.location?.shortPlaceLabel,
    ),
  );
}

Future<TeamMatchModel?> showCreatePostMatchPicker(BuildContext context) {
  return _showMentionSheet<TeamMatchModel>(
    context: context,
    title: 'Mention a match',
    hintText: 'Search matches',
    queryKeyPrefix: 'createPostMentionMatch',
    fetch: (query, page) async {
      return await MatchmakingService().listRequests(
            ListNegotiationsFilterQuery(
              scope: NegotiationListScope.all,
              type: NegotiationListType.all,
              search: query.isEmpty ? null : query,
              page: page,
              limit: 20,
            ),
          ) ??
          EmptyPaginatedResponse<TeamMatchModel>();
    },
    itemBuilder: (match) {
      final from = match.fromTeamHelper.getSubsetModel();
      final to = match.toTeamHelper.getSubsetModel();
      final date = createPostMatchScheduleLabel(match);
      final parts = <String>[
        if (date != null && date.isNotEmpty) date,
        match.sportType.label,
      ];
      return _MentionTile(
        leading: MatchPairLogos(
          leftUrl: createPostTeamLogoUrl(from?.logo),
          rightUrl: createPostTeamLogoUrl(to?.logo),
        ),
        title: match.versusLabel,
        subtitle: parts.join(' · '),
      );
    },
  );
}

Future<TurfModel?> showCreatePostTurfPicker(BuildContext context) {
  return _showMentionSheet<TurfModel>(
    context: context,
    title: 'Mention a turf',
    hintText: 'Search turfs',
    queryKeyPrefix: 'createPostMentionTurf',
    fetch: (query, page) async {
      return await TurfService().searchTurfs(
            globalSearchText: query.isEmpty ? null : query,
            page: page,
            limit: 20,
          ) ??
          EmptyPaginatedResponse<TurfModel>();
    },
    itemBuilder: (turf) => _MentionTile(
      leading: _TurfThumb(url: turf.mainImage),
      title: turf.displayName,
      subtitle: turf.location?.shortPlaceLabel ?? turf.location?.address,
    ),
  );
}

Future<T?> _showMentionSheet<T>({
  required BuildContext context,
  required String title,
  required String hintText,
  required String queryKeyPrefix,
  required Future<PaginatedResponse<T>> Function(String query, int page) fetch,
  required Widget Function(T item) itemBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _MentionSearchSheet<T>(
        title: title,
        hintText: hintText,
        queryKeyPrefix: queryKeyPrefix,
        fetch: fetch,
        itemBuilder: itemBuilder,
      );
    },
  );
}

class _MentionSearchSheet<T> extends HookWidget {
  const _MentionSearchSheet({
    required this.title,
    required this.hintText,
    required this.queryKeyPrefix,
    required this.fetch,
    required this.itemBuilder,
  });

  final String title;
  final String hintText;
  final String queryKeyPrefix;
  final Future<PaginatedResponse<T>> Function(String query, int page) fetch;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final submittedQuery = useState('');
    final debounce = useRef<Timer?>(null);

    useEffect(() {
      return () => debounce.value?.cancel();
    }, const []);

    final query =
        useInfiniteQuery<PaginatedResponse<T>, Object, int>(
      [queryKeyPrefix, submittedQuery.value],
      (ctx) async => fetch(submittedQuery.value, ctx.pageParam),
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final items =
        query.data?.pages.expand((p) => p.data).toList() ?? <T>[];
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: maxHeight,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.dividerColor),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppSearchField(
                  controller: searchController,
                  hintText: hintText,
                  autofocus: true,
                  onChanged: (value) {
                    debounce.value?.cancel();
                    debounce.value = Timer(
                      const Duration(milliseconds: 300),
                      () => submittedQuery.value = value.trim(),
                    );
                  },
                  onSubmitted: (value) {
                    debounce.value?.cancel();
                    submittedQuery.value = value.trim();
                  },
                  onCleared: () {
                    debounce.value?.cancel();
                    submittedQuery.value = '';
                  },
                ),
              ),
              Expanded(
                child: _MentionResults<T>(
                  query: query,
                  items: items,
                  itemBuilder: itemBuilder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MentionResults<T> extends StatelessWidget {
  const _MentionResults({
    required this.query,
    required this.items,
    required this.itemBuilder,
  });

  final InfiniteQueryResult<PaginatedResponse<T>, Object, int> query;
  final List<T> items;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
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
              'Could not load results',
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
      return const Center(
        child: Text(
          'No results',
          style: TextStyle(color: Color(AppColors.textSecondaryColor)),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          if (query.hasNextPage && !query.isFetchingNextPage) {
            query.fetchNextPage();
          }
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        itemCount: items.length + (query.isFetchingNextPage ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final item = items[index];
          return InkWell(
            onTap: () => Navigator.of(context).pop(item),
            child: itemBuilder(item),
          );
        },
      ),
    );
  }
}

class _MentionTile extends StatelessWidget {
  const _MentionTile({
    required this.leading,
    required this.title,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle?.trim();
    return ListTile(
      minLeadingWidth: 48,
      leading: leading,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(AppColors.textColor),
        ),
      ),
      subtitle: sub == null || sub.isEmpty
          ? null
          : Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}

class _TurfThumb extends StatelessWidget {
  const _TurfThumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 40,
        height: 40,
        child: url == null || url!.isEmpty
            ? Container(
                color: Colors.black12,
                child: const Icon(
                  AppIcons.turfPlaceholder,
                  color: Color(AppColors.primaryColor),
                ),
              )
            : AppNetworkImage(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.black12,
                  child: const Icon(AppIcons.turfPlaceholder),
                ),
              ),
      ),
    );
  }
}
