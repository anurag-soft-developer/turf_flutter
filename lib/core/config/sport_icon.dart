import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/sport_types.dart';

/// Renders a sport's SVG asset when present, otherwise its Material [Icon].
class SportIcon extends StatelessWidget {
  const SportIcon({
    super.key,
    required this.sport,
    this.size = 24,
    this.color,
  });

  final SportTypeConfig sport;
  final double size;
  final Color? color;

  factory SportIcon.forId({
    Key? key,
    required String id,
    double size = 24,
    Color? color,
  }) {
    final sport = SportTypes.byId(id) ??
        const SportTypeConfig(
          id: 'unknown',
          label: 'Sport',
          icon: Icons.sports,
          color: Colors.grey,
          gradient: [Colors.grey, Colors.grey],
        );
    return SportIcon(key: key, sport: sport, size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color ?? Colors.white;
    final asset = sport.iconAsset;
    if (asset != null && asset.isNotEmpty) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }
    return Icon(sport.icon, size: size, color: iconColor);
  }
}
