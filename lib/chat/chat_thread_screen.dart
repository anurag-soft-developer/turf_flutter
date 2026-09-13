import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/chat/chat_thread_controller.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/chat/utils/flyer_message_mapper.dart';
import 'package:flutter_application_1/components/chat/chat_date_header/chat_date_header.dart';
import 'package:flutter_application_1/components/chat/reaction_emoji_sheet.dart';
import 'package:flutter_application_1/components/chat/reply_composer.dart';
import 'package:flutter_application_1/components/chat/seen_avatars/seen_avatars.dart';
import 'package:flutter_application_1/components/chat/swipe_to_reply/swipe_to_reply.dart';
import 'package:flutter_application_1/components/chat/text_message_with_extras.dart';
import 'package:flutter_application_1/core/auth/auth_state_controller.dart';
import 'package:flutter_application_1/core/components/app_bar/app_bar_background.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get/get.dart';

class ChatThreadScreen extends StatelessWidget {
  const ChatThreadScreen({
    super.key,
    required this.scope,
    required this.scopeId,
    this.title,
    this.imageUrl,
  });

  final ChatScope scope;
  final String scopeId;
  final String? title;
  final String? imageUrl;

  static ChatThreadScreen fromRoute() {
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    final scope =
        ChatScope.fromApi(args['scope']?.toString()) ?? ChatScope.player;
    return ChatThreadScreen(
      scope: scope,
      scopeId: args['scopeId']?.toString() ?? '',
      title: args['title']?.toString(),
      imageUrl: args['imageUrl']?.toString(),
    );
  }

  String get _tag => chatRoomKey(scope, scopeId);

  @override
  Widget build(BuildContext context) {
    final me = Get.find<AuthStateController>().user?.id ?? '';
    if (scopeId.isEmpty || me.isEmpty) {
      return Scaffold(
        appBar: AppAppBar(title: Text(title ?? 'Chat')),
        body: const Center(child: Text('Unable to open this chat.')),
      );
    }

    return GetBuilder<ChatThreadController>(
      init: ChatThreadController(scope: scope, scopeId: scopeId),
      tag: _tag,
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(AppColors.backgroundColor),
          appBar: AppAppBar(
            title: Row(
              children: [
                if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(imageUrl!),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title ?? 'Chat', overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          body: Obx(() {
            if (controller.isLoadingInitial.value) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(AppColors.primaryColor),
                  ),
                ),
              );
            }
            return Chat(
              chatController: controller.chatController,
              currentUserId: me,
              resolveUser: controller.resolveUser,
              onMessageSend: controller.onSend,
              onMessageLongPress:
                  (context, message, {required index, required details}) {
                    unawaited(
                      _showMessageMenu(
                        context,
                        controller,
                        message,
                        details: details,
                        isMine: message.authorId == me,
                      ),
                    );
                  },
              builders: Builders(
                loadMoreBuilder: (_) => const SizedBox.shrink(),
                composerBuilder: (context) =>
                    ReplyComposer(controller: controller),
                textMessageBuilder:
                    (
                      context,
                      message,
                      index, {
                      required isSentByMe,
                      groupStatus,
                    }) {
                      return Obx(
                        () => TextMessageWithExtras(
                          message: message,
                          index: index,
                          isSentByMe: isSentByMe,
                          me: me,
                          highlighted:
                              controller.highlightedMessageId.value ==
                              message.id,
                          onReact: (emoji) =>
                              controller.reactToMessage(message.id, emoji),
                          onReplyTap: () {
                            final id = message.replyToMessageId;
                            if (id == null || id.isEmpty) return;
                            unawaited(controller.scrollToQuotedMessage(id));
                          },
                        ),
                      );
                    },
                chatMessageBuilder:
                    (
                      context,
                      message,
                      index,
                      animation,
                      child, {
                      isRemoved,
                      required isSentByMe,
                      groupStatus,
                    }) {
                      final bubble = isRemoved == true
                          ? child
                          : SwipeToReply(
                              key: ValueKey('swipe-reply-${message.id}'),
                              isMine: isSentByMe,
                              onReply: () => controller.setReplyTo(message),
                              child: child,
                            );
                      return ChatMessage(
                        message: message,
                        index: index,
                        animation: animation,
                        isRemoved: isRemoved,
                        groupStatus: groupStatus,
                        headerWidget: isRemoved == true
                            ? null
                            : chatDateHeaderFor(
                                messages: controller.chatController.messages,
                                message: message,
                                index: index,
                              ),
                        bottomWidget: isRemoved == true
                            ? null
                            : Obx(() {
                                final ids =
                                    controller.readersByMessageId[message.id];
                                if (ids == null || ids.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return SeenAvatars(
                                  key: ValueKey(
                                    'seen-${message.id}-${ids.join(',')}',
                                  ),
                                  userIds: ids,
                                  resolveUser: controller.resolveUser,
                                  onTap: () => unawaited(
                                    _showSeenBy(
                                      context,
                                      controller,
                                      userIds: ids,
                                    ),
                                  ),
                                );
                              }),
                        child: bubble,
                      );
                    },
                chatAnimatedListBuilder: (context, itemBuilder) {
                  return ChatAnimatedList(
                    itemBuilder: itemBuilder,
                    onEndReached: controller.loadEarlier,
                    physics: const ClampingScrollPhysics(),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _showMessageMenu(
    BuildContext context,
    ChatThreadController controller,
    Message message, {
    required LongPressStartDetails details,
    required bool isMine,
  }) async {
    const error = Color(AppColors.errorColor);
    const text = Color(AppColors.textColor);
    final action = await showMenu<String>(
      context: context,
      color: const Color(AppColors.surfaceColor).withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final emoji in kChatReactionEmojis)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context, 'react:$emoji'),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context, 'more-emoji'),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 22,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        const PopupMenuItem(
          value: 'reply',
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.reply, size: 16, color: text),
              SizedBox(width: 8),
              Text('Reply', style: TextStyle(fontSize: 13, color: text)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy',
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.copy_outlined, size: 16, color: text),
              SizedBox(width: 8),
              Text('Copy', style: TextStyle(fontSize: 13, color: text)),
            ],
          ),
        ),
        if (isMine)
          const PopupMenuItem(
            value: 'delete',
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: error, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
    if (!context.mounted || action == null) return;

    if (action.startsWith('react:')) {
      controller.reactToMessage(message.id, action.substring(6));
      return;
    }

    if (action == 'more-emoji') {
      final emoji = await showReactionEmojiSheet(context);
      if (!context.mounted || emoji == null || emoji.isEmpty) return;
      controller.reactToMessage(message.id, emoji);
      return;
    }

    switch (action) {
      case 'reply':
        controller.setReplyTo(message);
      case 'copy':
        await _copyMessage(message);
      case 'delete':
        await controller.deleteMessage(message.id);
    }
  }

  Future<void> _copyMessage(Message message) async {
    final text = message is TextMessage ? message.text : null;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _showSeenBy(
    BuildContext context,
    ChatThreadController controller, {
    List<String>? userIds,
  }) async {
    final names = await controller.seenByNames(userIds);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seen by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (names.isEmpty)
                  const Text('No one else has seen this yet.')
                else
                  ...names.map(
                    (name) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(name),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
