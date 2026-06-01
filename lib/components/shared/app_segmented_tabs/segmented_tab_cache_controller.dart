import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SegmentedTabPageResult<T> {
  const SegmentedTabPageResult({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
}

class SegmentedTabDataState<T> {
  const SegmentedTabDataState({
    this.items = const [],
    this.isFetching = false,
    this.isLoadingMore = false,
    this.error,
    this.hasInitialized = false,
    this.hasMore = false,
    this.loadedPage = 0,
  });

  final List<T> items;
  final bool isFetching;
  final bool isLoadingMore;
  final String? error;
  final bool hasInitialized;
  final bool hasMore;
  final int loadedPage;

  SegmentedTabDataState<T> copyWith({
    List<T>? items,
    bool? isFetching,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool? hasInitialized,
    bool? hasMore,
    int? loadedPage,
  }) {
    return SegmentedTabDataState<T>(
      items: items ?? this.items,
      isFetching: isFetching ?? this.isFetching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasInitialized: hasInitialized ?? this.hasInitialized,
      hasMore: hasMore ?? this.hasMore,
      loadedPage: loadedPage ?? this.loadedPage,
    );
  }
}

mixin SegmentedTabCacheController<K, T> on GetxController {
  List<K> get tabKeys;

  late final RxList<SegmentedTabDataState<T>> tabStateList = List.generate(
    tabKeys.length,
    (_) => SegmentedTabDataState<T>(),
  ).obs;

  @protected
  Future<List<T>> fetchTabItems(K key);

  @protected
  bool get paginatedTabs => false;

  @protected
  Future<SegmentedTabPageResult<T>> fetchTabPage(K key, int page) {
    throw UnimplementedError(
      'fetchTabPage must be implemented when paginatedTabs is true',
    );
  }

  @protected
  String mapFetchError(Object error) => 'Failed to load data';

  int tabIndexOf(K key) => tabKeys.indexOf(key);

  SegmentedTabDataState<T> tabStateFor(K key) {
    final index = tabIndexOf(key);
    if (index < 0 || index >= tabStateList.length) {
      return SegmentedTabDataState<T>();
    }
    return tabStateList[index];
  }

  @protected
  void setTabState(K key, SegmentedTabDataState<T> state) {
    final index = tabIndexOf(key);
    if (index < 0 || index >= tabStateList.length) return;
    tabStateList[index] = state;
    tabStateList.refresh();
  }

  Future<void> ensureTabLoaded(K key, {bool force = false}) async {
    final currentState = tabStateFor(key);
    if (!force && (currentState.isFetching || currentState.hasInitialized)) {
      return;
    }

    setTabState(
      key,
      currentState.copyWith(
        isFetching: true,
        isLoadingMore: false,
        clearError: true,
        hasMore: paginatedTabs ? true : currentState.hasMore,
        loadedPage: paginatedTabs ? 0 : currentState.loadedPage,
      ),
    );

    try {
      if (paginatedTabs) {
        final pageResult = await fetchTabPage(key, 1);
        setTabState(
          key,
          tabStateFor(key).copyWith(
            items: pageResult.items,
            isFetching: false,
            hasInitialized: true,
            loadedPage: pageResult.page,
            hasMore: pageResult.hasMore,
            clearError: true,
          ),
        );
      } else {
        final items = await fetchTabItems(key);
        setTabState(
          key,
          tabStateFor(key).copyWith(
            items: items,
            isFetching: false,
            hasInitialized: true,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      setTabState(
        key,
        tabStateFor(key).copyWith(
          isFetching: false,
          hasInitialized: true,
          error: mapFetchError(e),
        ),
      );
    } finally {
      if (tabStateFor(key).isFetching) {
        setTabState(
          key,
          tabStateFor(key).copyWith(isFetching: false),
        );
      }
    }
  }

  Future<void> loadMoreTab(K key) async {
    if (!paginatedTabs) return;

    final currentState = tabStateFor(key);
    if (currentState.isFetching ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    setTabState(
      key,
      currentState.copyWith(isLoadingMore: true, clearError: true),
    );

    try {
      final pageResult = await fetchTabPage(key, currentState.loadedPage + 1);
      final latestState = tabStateFor(key);
      setTabState(
        key,
        latestState.copyWith(
          items: [...latestState.items, ...pageResult.items],
          isLoadingMore: false,
          loadedPage: pageResult.page,
          hasMore: pageResult.hasMore,
        ),
      );
    } catch (_) {
      setTabState(
        key,
        tabStateFor(key).copyWith(isLoadingMore: false),
      );
    }
  }
}
