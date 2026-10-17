enum ExploreCategory {
  all,
  tournament,
  match,
  team,
  player,
  post;

  String get apiValue => name;

  bool get isConcrete => this != ExploreCategory.all;
}
