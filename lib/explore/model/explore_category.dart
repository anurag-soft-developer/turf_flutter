enum ExploreCategory {
  all,
  match,
  team,
  player,
  post;

  String get apiValue => name;

  bool get isConcrete => this != ExploreCategory.all;
}
