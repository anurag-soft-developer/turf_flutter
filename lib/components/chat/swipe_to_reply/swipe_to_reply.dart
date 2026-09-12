import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:get/get.dart';

import 'swipe_to_reply_controller.dart';

class SwipeToReply extends StatelessWidget {
  const SwipeToReply({
    super.key,
    required this.isMine,
    required this.onReply,
    required this.child,
  });

  final bool isMine;
  final VoidCallback onReply;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SwipeToReplyController>(
      init: SwipeToReplyController(isMine: isMine, onReply: onReply),
      global: false,
      builder: (controller) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: controller.onDragStart,
          onHorizontalDragUpdate: controller.onDragUpdate,
          onHorizontalDragEnd: controller.onDragEnd,
          onHorizontalDragCancel: controller.onDragCancel,
          child: Obx(() {
            final drag = controller.drag.value;
            final progress = controller.progress;
            return Stack(
              clipBehavior: Clip.none,
              alignment:
                  isMine ? Alignment.centerRight : Alignment.centerLeft,
              children: [
                Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: 0.7 + (0.3 * progress),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.reply_rounded,
                        color: const Color(
                          AppColors.primaryColor,
                        ).withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(drag, 0),
                  child: child,
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
