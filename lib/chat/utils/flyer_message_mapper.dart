import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';

TextMessage toFlyerTextMessage(ChatMessageModel message) {
  return TextMessage(
    id: message.messageId,
    authorId: message.senderUserId,
    createdAt: message.createdAtDate?.toUtc() ?? DateTime.now().toUtc(),
    text: message.body,
  );
}
