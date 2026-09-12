import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';

const kChatReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

TextMessage toFlyerTextMessage(ChatMessageModel message) {
  return TextMessage(
    id: message.messageId,
    authorId: message.senderUserId,
    createdAt: message.createdAtDate?.toUtc() ?? DateTime.now().toUtc(),
    text: message.body,
    replyToMessageId: message.replyToMessageId,
    reactions: message.reactions.isEmpty ? null : message.reactions,
    metadata: {
      if (message.replyToBody != null && message.replyToBody!.isNotEmpty)
        'replyToBody': message.replyToBody,
      if (message.replyToSenderUserId != null &&
          message.replyToSenderUserId!.isNotEmpty)
        'replyToSenderUserId': message.replyToSenderUserId,
    },
  );
}

TextMessage withReactions(
  TextMessage message,
  Map<String, List<String>> reactions,
) {
  return message.copyWith(
    reactions: reactions.isEmpty ? null : reactions,
  );
}
