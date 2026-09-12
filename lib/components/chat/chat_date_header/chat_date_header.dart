import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

import 'chat_date_header_controller.dart';

class ChatDateHeader extends StatelessWidget {
  const ChatDateHeader({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatDateHeaderController>(
      init: ChatDateHeaderController(date: date),
      global: false,
      builder: (controller) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(AppColors.surfaceColor),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(AppColors.dividerColor)),
              ),
              child: Obx(
                () => Text(
                  controller.label.value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget? chatDateHeaderFor({
  required List<Message> messages,
  required Message message,
  required int index,
}) {
  final createdAt = message.createdAt;
  if (createdAt == null) return null;
  final prev = index > 0 && index < messages.length ? messages[index - 1] : null;
  if (prev != null &&
      ChatDateHeaderController.sameDay(createdAt, prev.createdAt)) {
    return null;
  }
  return ChatDateHeader(date: createdAt);
}
