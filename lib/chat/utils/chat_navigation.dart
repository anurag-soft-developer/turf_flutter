import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:get/get.dart';

class ChatNavigation {
  ChatNavigation._();

  static Future<dynamic>? openThread({
    required ChatScope scope,
    required String scopeId,
    String? title,
    String? imageUrl,
  }) {
    if (scopeId.trim().isEmpty) return null;
    return Get.toNamed(
      AppConstants.routes.chatThread,
      arguments: {
        'scope': scope.apiValue,
        'scopeId': scopeId.trim(),
        if (title != null) 'title': title,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
  }

  static Future<dynamic>? openTeam(
    String teamId, {
    String? title,
    String? imageUrl,
  }) {
    return openThread(
      scope: ChatScope.team,
      scopeId: teamId,
      title: title,
      imageUrl: imageUrl,
    );
  }

  static Future<dynamic>? openMatch(
    String matchId, {
    String? title,
    String? imageUrl,
  }) {
    return openThread(
      scope: ChatScope.match,
      scopeId: matchId,
      title: title,
      imageUrl: imageUrl,
    );
  }

  static Future<dynamic>? openPlayer({
    required String myUserId,
    required String otherUserId,
    String? title,
    String? imageUrl,
  }) {
    if (myUserId.isEmpty || otherUserId.isEmpty || myUserId == otherUserId) {
      return null;
    }
    return openThread(
      scope: ChatScope.player,
      scopeId: normalizePlayerScopeId(myUserId, otherUserId),
      title: title,
      imageUrl: imageUrl,
    );
  }
}
