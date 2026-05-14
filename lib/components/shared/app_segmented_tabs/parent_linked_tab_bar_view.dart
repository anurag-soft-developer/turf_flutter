import 'package:flutter/material.dart';

/// Forwards horizontal swipes to [parentController] when [childController]
/// is already on its first or last tab.
class ParentLinkedTabBarView extends StatefulWidget {
  const ParentLinkedTabBarView({
    super.key,
    required this.childController,
    required this.parentController,
    required this.children,
    this.physics,
    this.minSwipeDistance = 42,
  });

  final TabController childController;
  final TabController parentController;
  final List<Widget> children;
  final ScrollPhysics? physics;
  final double minSwipeDistance;

  @override
  State<ParentLinkedTabBarView> createState() => _ParentLinkedTabBarViewState();
}

class _ParentLinkedTabBarViewState extends State<ParentLinkedTabBarView> {
  Offset? _pointerDown;

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown = event.position;
  }

  void _onPointerUp(PointerUpEvent event) {
    final start = _pointerDown;
    _pointerDown = null;
    if (start == null) return;

    final delta = event.position - start;
    if (delta.dx.abs() <= delta.dy.abs()) return;
    if (delta.dx.abs() < widget.minSwipeDistance) return;

    final child = widget.childController;
    final parent = widget.parentController;
    if (!child.indexIsChanging && !parent.indexIsChanging) {
      if (delta.dx < 0 &&
          child.index >= child.length - 1 &&
          parent.index < parent.length - 1) {
        parent.animateTo(parent.index + 1);
        return;
      }
      if (delta.dx > 0 && child.index <= 0 && parent.index > 0) {
        parent.animateTo(parent.index - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _pointerDown = null,
      child: TabBarView(
        controller: widget.childController,
        physics: widget.physics,
        children: widget.children,
      ),
    );
  }
}

/// Forwards horizontal swipes to [parentController] when there is no nested tab
/// view to consume them.
class ParentLinkedHorizontalSwipe extends StatefulWidget {
  const ParentLinkedHorizontalSwipe({
    super.key,
    required this.parentController,
    required this.child,
    this.minSwipeDistance = 42,
  });

  final TabController parentController;
  final Widget child;
  final double minSwipeDistance;

  @override
  State<ParentLinkedHorizontalSwipe> createState() =>
      _ParentLinkedHorizontalSwipeState();
}

class _ParentLinkedHorizontalSwipeState extends State<ParentLinkedHorizontalSwipe> {
  Offset? _pointerDown;

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown = event.position;
  }

  void _onPointerUp(PointerUpEvent event) {
    final start = _pointerDown;
    _pointerDown = null;
    if (start == null) return;

    final delta = event.position - start;
    if (delta.dx.abs() <= delta.dy.abs()) return;
    if (delta.dx.abs() < widget.minSwipeDistance) return;

    final parent = widget.parentController;
    if (parent.indexIsChanging) return;

    if (delta.dx < 0 && parent.index < parent.length - 1) {
      parent.animateTo(parent.index + 1);
      return;
    }
    if (delta.dx > 0 && parent.index > 0) {
      parent.animateTo(parent.index - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _pointerDown = null,
      child: widget.child,
    );
  }
}
