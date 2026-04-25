import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SegmentedTabDataState<T> {
  const SegmentedTabDataState({
    this.items = const [],
    this.isFetching = false,
    this.error,
    this.hasInitialized = false,
  });

  final List<T> items;
  final bool isFetching;
  final String? error;
  final bool hasInitialized;

  SegmentedTabDataState<T> copyWith({
    List<T>? items,
    bool? isFetching,
    String? error,
    bool clearError = false,
    bool? hasInitialized,
  }) {
    return SegmentedTabDataState<T>(
      items: items ?? this.items,
      isFetching: isFetching ?? this.isFetching,
      error: clearError ? null : (error ?? this.error),
      hasInitialized: hasInitialized ?? this.hasInitialized,
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
      currentState.copyWith(isFetching: true, clearError: true),
    );

    try {
      final items = await fetchTabItems(key);
      setTabState(
        key,
        tabStateFor(
          key,
        ).copyWith(
          items: items,
          isFetching: false,
          hasInitialized: true,
          clearError: true,
        ),
      );
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
}
