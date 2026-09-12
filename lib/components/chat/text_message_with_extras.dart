import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class TextMessageWithExtras extends StatelessWidget {
  const TextMessageWithExtras({
    super.key,
    required this.message,
    required this.index,
    required this.isSentByMe,
    required this.me,
    required this.onReact,
    this.onReplyTap,
    this.highlighted = false,
  });

  final TextMessage message;
  final int index;
  final bool isSentByMe;
  final String me;
  final ValueChanged<String> onReact;
  final VoidCallback? onReplyTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final replyBody = message.metadata?['replyToBody']?.toString();
    final reactions = message.reactions ?? const <String, List<String>>{};

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (replyBody != null && replyBody.isNotEmpty)
              GestureDetector(
                onTap: onReplyTap,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.dividerColor)
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border(
                      left: BorderSide(
                        color: Color(AppColors.primaryColor),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    replyBody,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
              ),
            SimpleTextMessage(message: message, index: index),
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final entry in reactions.entries)
                      if (entry.value.isNotEmpty)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onReact(entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: entry.value.contains(me)
                                  ? const Color(AppColors.primaryColor)
                                      .withValues(alpha: 0.15)
                                  : const Color(AppColors.surfaceColor),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(AppColors.dividerColor),
                              ),
                            ),
                            child: Text(
                              '${entry.key} ${entry.value.length}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: highlighted ? 1 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSentByMe
                      ? Colors.white.withValues(alpha: 0.32)
                      : const Color(AppColors.primaryColor)
                          .withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
