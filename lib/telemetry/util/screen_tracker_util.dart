class ScreenTracker {
  String? route;
  DateTime? enteredAt;

  bool get hasOpenVisit => route != null && enteredAt != null;

  void open(String nextRoute, DateTime at) {
    route = nextRoute;
    enteredAt = at;
  }

  /// Closes the in-memory visit. Nothing is written here.
  ({String route, DateTime enteredAt})? take() {
    final currentRoute = route;
    final at = enteredAt;
    route = null;
    enteredAt = null;
    if (currentRoute == null || at == null) return null;
    return (route: currentRoute, enteredAt: at);
  }
}
