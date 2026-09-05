import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/chat_thread_controller.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/core/auth/auth_state_controller.dart';
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
        appBar: AppBar(title: Text(title ?? 'Chat')),
        body: const Center(child: Text('Unable to open this chat.')),
      );
    }

    return GetBuilder<ChatThreadController>(
      init: ChatThreadController(scope: scope, scopeId: scopeId),
      tag: _tag,
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(AppColors.backgroundColor),
          appBar: AppBar(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title ?? 'Chat', overflow: TextOverflow.ellipsis),
                      Obx(() {
                        final subtitle = controller.seenSubtitle.value;
                        if (subtitle == null) return const SizedBox.shrink();
                        return Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (scope != ChatScope.player)
                IconButton(
                  tooltip: 'Seen by',
                  onPressed: () => _showSeenBy(context, controller),
                  icon: const Icon(Icons.visibility_outlined),
                ),
            ],
          ),
          body: Chat(
            chatController: controller.chatController,
            currentUserId: me,
            resolveUser: controller.resolveUser,
            onMessageSend: controller.onSend,
            builders: Builders(
              chatAnimatedListBuilder: (context, itemBuilder) {
                return ChatAnimatedList(
                  itemBuilder: itemBuilder,
                  onEndReached: controller.loadEarlier,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSeenBy(
    BuildContext context,
    ChatThreadController controller,
  ) async {
    final names = await controller.seenByNames();
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
