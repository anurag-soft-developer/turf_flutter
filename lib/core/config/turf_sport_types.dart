import 'package:flutter/material.dart';

class TurfSportType {
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const TurfSportType({
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

/// Canonical turf sport type values shared across dashboard, filters, and API calls.
class TurfSportTypes {
  TurfSportTypes._();

  static const String all = 'All';

  static final List<TurfSportType> filterable = [
    TurfSportType(
      value: 'Football',
      icon: Icons.sports_soccer,
      color: Colors.green,
      gradient: [Colors.green.shade400, Colors.green.shade600],
    ),
    TurfSportType(
      value: 'Cricket',
      icon: Icons.sports_cricket,
      color: Colors.orange,
      gradient: [Colors.orange.shade400, Colors.orange.shade600],
    ),
    TurfSportType(
      value: 'Basketball',
      icon: Icons.sports_basketball,
      color: Colors.deepOrange,
      gradient: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
    ),
    TurfSportType(
      value: 'Badminton',
      icon: Icons.sports_tennis,
      color: Colors.blue,
      gradient: [Colors.blue.shade400, Colors.blue.shade600],
    ),
    TurfSportType(
      value: 'Tennis',
      icon: Icons.sports_tennis,
      color: Colors.lightGreen,
      gradient: [Colors.lightGreen.shade400, Colors.lightGreen.shade700],
    ),
    TurfSportType(
      value: 'Volleyball',
      icon: Icons.sports_volleyball,
      color: Colors.purple,
      gradient: [Colors.purple.shade400, Colors.purple.shade600],
    ),
    TurfSportType(
      value: 'Hockey',
      icon: Icons.sports_hockey,
      color: Colors.blueGrey,
      gradient: [Colors.blueGrey.shade400, Colors.blueGrey.shade700],
    ),
  ];

  static List<String> get filterableValues =>
      filterable.map((sport) => sport.value).toList();

  static bool isAll(String sportType) => sportType == all;
}
