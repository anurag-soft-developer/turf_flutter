import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../core/config/constants.dart';
import '../../core/query/query_retry.dart';
import '../model/tournament_models.dart';

class TournamentInfiniteQueryPane extends HookWidget {
  const TournamentInfiniteQueryPane({
    super.key,
    required this.queryKey,
    required this.fetchPage,
    required this.itemBuilder,
    required this.empty,
    this.listPadding = const EdgeInsets.fromLTRB(16, 8, 16, 96),
  });

  final List<Object?> queryKey;
  final Future<TournamentPage> Function(int page) fetchPage;
  final Widget Function(TournamentModel tournament, int index, int total)
      itemBuilder;
  final Widget empty;
  final EdgeInsetsGeometry listPadding;

  @override
  Widget build(BuildContext context) {
    final query = useInfiniteQuery<TournamentPage, Object, int>(
      queryKey,
      (ctx) => fetchPage(ctx.pageParam),
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final list =
        query.data?.pages.expand((p) => p.items).toList() ??
        const <TournamentModel>[];

    if (query.isLoading || (query.isFetching && list.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.35,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 42,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load',
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontSize: 15,
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
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => query.refetch(),
      color: const Color(AppColors.primaryColor),
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.45,
                  child: empty,
                ),
              ],
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
                  if (query.hasNextPage && !query.isFetchingNextPage) {
                    query.fetchNextPage();
                  }
                }
                return false;
              },
              child: ListView.builder(
                padding: listPadding,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length + (query.isFetchingNextPage ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == list.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(AppColors.primaryColor),
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < list.length - 1 ? 8 : 0,
                    ),
                    child: itemBuilder(list[i], i, list.length),
                  );
                },
              ),
            ),
    );
  }
}
