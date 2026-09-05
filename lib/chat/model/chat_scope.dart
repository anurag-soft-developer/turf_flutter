enum ChatScope {
  team,
  match,
  player;

  String get apiValue => name;

  static ChatScope? fromApi(String? raw) {
    switch (raw) {
      case 'team':
        return ChatScope.team;
      case 'match':
        return ChatScope.match;
      case 'player':
        return ChatScope.player;
      default:
        return null;
    }
  }
}

String chatRoomKey(ChatScope scope, String scopeId) =>
    '${scope.apiValue}:$scopeId';

String normalizePlayerScopeId(String firstUserId, String secondUserId) {
  final ids = [firstUserId.trim(), secondUserId.trim()]..sort();
  return ids.join(':');
}

String? otherPlayerId(String scopeId, String userId) {
  final parts = scopeId.split(':').where((part) => part.isNotEmpty).toList();
  if (parts.length != 2) return null;
  if (parts[0] == userId) return parts[1];
  if (parts[1] == userId) return parts[0];
  return null;
}
