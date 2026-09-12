import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SwipeToReplyController extends GetxController
    with GetSingleTickerProviderStateMixin {
  SwipeToReplyController({
    required this.isMine,
    required this.onReply,
  });

  final bool isMine;
  final VoidCallback onReply;

  static const maxDrag = 72.0;
  static const trigger = 48.0;

  final drag = 0.0.obs;

  late final AnimationController _settle;
  late Animation<double> _animation;
  bool _armed = false;

  double get progress => (drag.value.abs() / maxDrag).clamp(0.0, 1.0);

  @override
  void onInit() {
    super.onInit();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(_onSettleTick);
  }

  @override
  void onClose() {
    _settle.dispose();
    super.onClose();
  }

  void onDragStart(DragStartDetails _) {
    _settle.stop();
    _armed = false;
  }

  void onDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    final next = isMine
        ? (drag.value + delta).clamp(-maxDrag, 0.0)
        : (drag.value + delta).clamp(0.0, maxDrag);
    final armed = next.abs() >= trigger;
    if (armed && !_armed) {
      HapticFeedback.selectionClick();
    }
    _armed = armed;
    drag.value = next;
  }

  void onDragEnd(DragEndDetails _) {
    _settleBack();
  }

  void onDragCancel() {
    _settleBack();
  }

  void _onSettleTick() {
    drag.value = _animation.value;
  }

  void _settleBack() {
    if (_armed) onReply();
    _armed = false;
    _animation = Tween<double>(begin: drag.value, end: 0).animate(
      CurvedAnimation(parent: _settle, curve: Curves.easeOutCubic),
    );
    _settle.forward(from: 0);
  }
}
