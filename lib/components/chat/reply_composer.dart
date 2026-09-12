import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/chat_thread_controller.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get/get.dart';

/// Must return a [Composer] (or other [Positioned] root) — [Chat] places it in a [Stack].
class ReplyComposer extends StatelessWidget {
  const ReplyComposer({super.key, required this.controller});

  final ChatThreadController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reply = controller.replyTo.value;
      return Composer(
        topWidget: reply == null
            ? null
            : Material(
                color: const Color(AppColors.surfaceColor),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(AppColors.dividerColor)),
                      left: BorderSide(
                        color: Color(AppColors.primaryColor),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.reply,
                        size: 18,
                        color: Color(AppColors.primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.scrollToQuotedMessage(
                            reply.messageId,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Replying',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(AppColors.primaryColor),
                                ),
                              ),
                              Text(
                                reply.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(AppColors.textSecondaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancel reply',
                        onPressed: controller.clearReply,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
      );
    });
  }
}
