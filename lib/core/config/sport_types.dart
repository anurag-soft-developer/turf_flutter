import 'package:flutter/material.dart';

/// Canonical sport type IDs (lowercase slugs) — must stay in sync with backend
/// SportType enum in sport-types.ts:
/// football, cricket, basketball, badminton, tennis, volleyball, hockey,
/// table_tennis, squash, futsal, kabaddi, pickleball, rugby, baseball,
/// softball, handball, throwball, netball, athletics, boxing, martial_arts,
/// skating, golf, swimming
class SportTypeConfig {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final bool rankingEnabled;

  const SportTypeConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
    this.rankingEnabled = false,
  });
}

class SportTypes {
  SportTypes._();

  static const String all = 'all';

  static const List<SportTypeConfig> catalog = [
    SportTypeConfig(
      id: 'football',
      label: 'Football',
      icon: Icons.sports_soccer,
      color: Colors.green,
      gradient: [Color(0xFF66BB6A), Color(0xFF388E3C)],
      rankingEnabled: true,
    ),
    SportTypeConfig(
      id: 'cricket',
      label: 'Cricket',
      icon: Icons.sports_cricket,
      color: Colors.orange,
      gradient: [Color(0xFFFFA726), Color(0xFFEF6C00)],
      rankingEnabled: true,
    ),
    SportTypeConfig(
      id: 'basketball',
      label: 'Basketball',
      icon: Icons.sports_basketball,
      color: Colors.deepOrange,
      gradient: [Color(0xFFFF7043), Color(0xFFD84315)],
    ),
    SportTypeConfig(
      id: 'badminton',
      label: 'Badminton',
      icon: Icons.sports_tennis,
      color: Colors.blue,
      gradient: [Color(0xFF42A5F5), Color(0xFF1565C0)],
    ),
    SportTypeConfig(
      id: 'tennis',
      label: 'Tennis',
      icon: Icons.sports_tennis,
      color: Colors.lightGreen,
      gradient: [Color(0xFF9CCC65), Color(0xFF558B2F)],
    ),
    SportTypeConfig(
      id: 'volleyball',
      label: 'Volleyball',
      icon: Icons.sports_volleyball,
      color: Colors.purple,
      gradient: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
    ),
    SportTypeConfig(
      id: 'hockey',
      label: 'Hockey',
      icon: Icons.sports_hockey,
      color: Colors.blueGrey,
      gradient: [Color(0xFF78909C), Color(0xFF37474F)],
    ),
    SportTypeConfig(
      id: 'table_tennis',
      label: 'Table Tennis',
      icon: Icons.sports_tennis,
      color: Colors.teal,
      gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
    ),
    SportTypeConfig(
      id: 'squash',
      label: 'Squash',
      icon: Icons.sports_tennis,
      color: Colors.indigo,
      gradient: [Color(0xFF5C6BC0), Color(0xFF283593)],
    ),
    SportTypeConfig(
      id: 'futsal',
      label: 'Futsal',
      icon: Icons.sports_soccer,
      color: Colors.green,
      gradient: [Color(0xFF81C784), Color(0xFF2E7D32)],
    ),
    SportTypeConfig(
      id: 'kabaddi',
      label: 'Kabaddi',
      icon: Icons.sports_martial_arts,
      color: Colors.red,
      gradient: [Color(0xFFEF5350), Color(0xFFC62828)],
    ),
    SportTypeConfig(
      id: 'pickleball',
      label: 'Pickleball',
      icon: Icons.sports_tennis,
      color: Colors.cyan,
      gradient: [Color(0xFF26C6DA), Color(0xFF00838F)],
    ),
    SportTypeConfig(
      id: 'rugby',
      label: 'Rugby',
      icon: Icons.sports_rugby,
      color: Colors.brown,
      gradient: [Color(0xFF8D6E63), Color(0xFF4E342E)],
    ),
    SportTypeConfig(
      id: 'baseball',
      label: 'Baseball',
      icon: Icons.sports_baseball,
      color: Colors.amber,
      gradient: [Color(0xFFFFCA28), Color(0xFFF57F17)],
    ),
    SportTypeConfig(
      id: 'softball',
      label: 'Softball',
      icon: Icons.sports_baseball,
      color: Colors.yellow,
      gradient: [Color(0xFFFFEE58), Color(0xFFF9A825)],
    ),
    SportTypeConfig(
      id: 'handball',
      label: 'Handball',
      icon: Icons.sports_handball,
      color: Colors.deepPurple,
      gradient: [Color(0xFF7E57C2), Color(0xFF4527A0)],
    ),
    SportTypeConfig(
      id: 'throwball',
      label: 'Throwball',
      icon: Icons.sports_volleyball,
      color: Colors.pink,
      gradient: [Color(0xFFEC407A), Color(0xFFC2185B)],
    ),
    SportTypeConfig(
      id: 'netball',
      label: 'Netball',
      icon: Icons.sports_volleyball,
      color: Colors.lime,
      gradient: [Color(0xFFD4E157), Color(0xFF9E9D24)],
    ),
    SportTypeConfig(
      id: 'athletics',
      label: 'Athletics',
      icon: Icons.directions_run,
      color: Colors.orange,
      gradient: [Color(0xFFFFB74D), Color(0xFFE65100)],
    ),
    SportTypeConfig(
      id: 'boxing',
      label: 'Boxing',
      icon: Icons.sports_martial_arts,
      color: Colors.redAccent,
      gradient: [Color(0xFFFF5252), Color(0xFFD50000)],
    ),
    SportTypeConfig(
      id: 'martial_arts',
      label: 'Martial Arts',
      icon: Icons.sports_martial_arts,
      color: Colors.grey,
      gradient: [Color(0xFF90A4AE), Color(0xFF455A64)],
    ),
    SportTypeConfig(
      id: 'skating',
      label: 'Skating',
      icon: Icons.ice_skating,
      color: Colors.lightBlue,
      gradient: [Color(0xFF4FC3F7), Color(0xFF0277BD)],
    ),
    SportTypeConfig(
      id: 'golf',
      label: 'Golf',
      icon: Icons.sports_golf,
      color: Colors.green,
      gradient: [Color(0xFFA5D6A7), Color(0xFF1B5E20)],
    ),
    SportTypeConfig(
      id: 'swimming',
      label: 'Swimming',
      icon: Icons.pool,
      color: Colors.blue,
      gradient: [Color(0xFF29B6F6), Color(0xFF01579B)],
    ),
  ];

  static List<SportTypeConfig> get rankingFilterable =>
      catalog.where((s) => s.rankingEnabled).toList();

  static SportTypeConfig? byId(String id) {
    final normalized = id.trim().toLowerCase();
    for (final sport in catalog) {
      if (sport.id == normalized) return sport;
    }
    return null;
  }

  static String labelFor(String id) => byId(id)?.label ?? id;

  static IconData iconFor(String id) => byId(id)?.icon ?? Icons.sports;

  static bool isAll(String sportType) =>
      sportType.trim().toLowerCase() == all;
}
