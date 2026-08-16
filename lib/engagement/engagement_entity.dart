enum EngagementEntityType {
  post,
  match,
  team,
  player;

  String get apiValue => name;
}

enum EngagementEventKind {
  impression,
  view,
  watch;

  String get apiValue => name;
}
