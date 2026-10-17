import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../bottom_navigation_panel/navigation_controller.dart';

const kTabScrollTopThreshold = 1.0;
const kTabScrollTopDuration = Duration(milliseconds: 350);

/// Scrolls [controller] to its start. Returns false when it is already there.
Future<bool> animateScrollToTop(ScrollController controller) async {
  if (!controller.hasClients) return false;
  final targets = _pastTop(controller.positions);
  if (targets.isEmpty) return false;
  await Future.wait(targets.map(_animateToMin));
  return true;
}

/// Scrolls a [NestedScrollView] / [ExtendedNestedScrollView] to the top.
///
/// Driving the outer position also brings the inner body back to its start
/// in the same animation.
Future<bool> animateNestedScrollToTop({
  required ScrollController outer,
  Iterable<ScrollPosition> inners = const [],
}) async {
  if (!outer.hasClients) return false;
  final needsScroll =
      _pastTop(outer.positions).isNotEmpty || _pastTop(inners).isNotEmpty;
  if (!needsScroll) return false;
  await _animateToMin(outer.positions.first);
  return true;
}

void bindTabScrollToTop(String label, Future<bool> Function() action) {
  if (!Get.isRegistered<NavigationController>()) return;
  Get.find<NavigationController>().bindScrollToTop(label, action);
}

void unbindTabScrollToTop(String label, Future<bool> Function() action) {
  if (!Get.isRegistered<NavigationController>()) return;
  Get.find<NavigationController>().unbindScrollToTop(label, action);
}

void bindTabRefresh(String label, Future<bool> Function() action) {
  if (!Get.isRegistered<NavigationController>()) return;
  Get.find<NavigationController>().bindTabRefresh(label, action);
}

void unbindTabRefresh(String label, Future<bool> Function() action) {
  if (!Get.isRegistered<NavigationController>()) return;
  Get.find<NavigationController>().unbindTabRefresh(label, action);
}

/// Plays the pull-to-refresh spinner and runs [RefreshIndicator.onRefresh].
/// Returns false when the indicator is not mounted.
Future<bool> showTabRefreshIndicator(
  GlobalKey<RefreshIndicatorState> key,
) async {
  final indicator = key.currentState;
  if (indicator == null) return false;
  await indicator.show();
  return true;
}

/// Call from a [HookWidget] build method.
void useBindTabScroll(String label, ScrollController controller) {
  useEffect(() {
    Future<bool> action() => animateScrollToTop(controller);
    bindTabScrollToTop(label, action);
    return () => unbindTabScrollToTop(label, action);
  }, [label, controller]);
}

/// Call from a [HookWidget] build method.
void useBindTabRefresh(
  String label,
  GlobalKey<RefreshIndicatorState> indicatorKey,
) {
  useEffect(() {
    Future<bool> action() => showTabRefreshIndicator(indicatorKey);
    bindTabRefresh(label, action);
    return () => unbindTabRefresh(label, action);
  }, [label, indicatorKey]);
}

List<ScrollPosition> _pastTop(Iterable<ScrollPosition> positions) {
  return [
    for (final position in positions)
      if (position.hasPixels &&
          position.hasContentDimensions &&
          position.pixels > position.minScrollExtent + kTabScrollTopThreshold)
        position,
  ];
}

Future<void> _animateToMin(ScrollPosition position) {
  return position.animateTo(
    position.minScrollExtent,
    duration: kTabScrollTopDuration,
    curve: Curves.easeOutCubic,
  );
}
