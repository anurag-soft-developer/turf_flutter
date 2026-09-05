import 'chat_scope.dart';

class ChatMessageModel {
  final String messageId;
  final ChatScope scope;
  final String scopeId;
  final String senderUserId;
  final String body;
  final String createdAt;

  const ChatMessageModel({
    required this.messageId,
    required this.scope,
    required this.scopeId,
    required this.senderUserId,
    required this.body,
    required this.createdAt,
  });

  DateTime? get createdAtDate {
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return null;
    }
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: json['messageId']?.toString() ?? '',
      scope: ChatScope.fromApi(json['scope']?.toString()) ?? ChatScope.player,
      scopeId: json['scopeId']?.toString() ?? '',
      senderUserId: json['senderUserId']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class ChatInboxItem {
  final ChatScope scope;
  final String scopeId;
  final String title;
  final String? imageUrl;
  final String lastMessageId;
  final String lastMessageBody;
  final String lastSenderUserId;
  final String lastMessageAt;
  final int unreadCount;

  const ChatInboxItem({
    required this.scope,
    required this.scopeId,
    required this.title,
    this.imageUrl,
    required this.lastMessageId,
    required this.lastMessageBody,
    required this.lastSenderUserId,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  String get roomKey => chatRoomKey(scope, scopeId);

  DateTime? get lastMessageAtDate {
    try {
      return DateTime.parse(lastMessageAt);
    } catch (_) {
      return null;
    }
  }

  ChatInboxItem copyWith({
    String? title,
    String? imageUrl,
    String? lastMessageId,
    String? lastMessageBody,
    String? lastSenderUserId,
    String? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatInboxItem(
      scope: scope,
      scopeId: scopeId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageBody: lastMessageBody ?? this.lastMessageBody,
      lastSenderUserId: lastSenderUserId ?? this.lastSenderUserId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatInboxItem.fromJson(Map<String, dynamic> json) {
    return ChatInboxItem(
      scope: ChatScope.fromApi(json['scope']?.toString()) ?? ChatScope.player,
      scopeId: json['scopeId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Chat',
      imageUrl: json['imageUrl']?.toString(),
      lastMessageId: json['lastMessageId']?.toString() ?? '',
      lastMessageBody: json['lastMessageBody']?.toString() ?? '',
      lastSenderUserId: json['lastSenderUserId']?.toString() ?? '',
      lastMessageAt: json['lastMessageAt']?.toString() ?? '',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory ChatInboxItem.fromInboxUpdated(
    Map<String, dynamic> json, {
    String title = 'Chat',
    String? imageUrl,
    int unreadCount = 0,
  }) {
    return ChatInboxItem(
      scope: ChatScope.fromApi(json['scope']?.toString()) ?? ChatScope.player,
      scopeId: json['scopeId']?.toString() ?? '',
      title: title,
      imageUrl: imageUrl,
      lastMessageId: json['lastMessageId']?.toString() ?? '',
      lastMessageBody: json['lastMessageBody']?.toString() ?? '',
      lastSenderUserId: json['lastSenderUserId']?.toString() ?? '',
      lastMessageAt: json['lastMessageAt']?.toString() ?? '',
      unreadCount: unreadCount,
    );
  }
}

class ChatReadCursor {
  final String userId;
  final DateTime lastReadAt;

  const ChatReadCursor({required this.userId, required this.lastReadAt});

  factory ChatReadCursor.fromJson(Map<String, dynamic> json) {
    return ChatReadCursor(
      userId: json['userId']?.toString() ?? '',
      lastReadAt: DateTime.tryParse(json['lastReadAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ChatReadEvent {
  final ChatScope scope;
  final String scopeId;
  final String userId;
  final DateTime lastReadAt;

  const ChatReadEvent({
    required this.scope,
    required this.scopeId,
    required this.userId,
    required this.lastReadAt,
  });

  factory ChatReadEvent.fromJson(Map<String, dynamic> json) {
    return ChatReadEvent(
      scope: ChatScope.fromApi(json['scope']?.toString()) ?? ChatScope.player,
      scopeId: json['scopeId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      lastReadAt: DateTime.tryParse(json['lastReadAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
