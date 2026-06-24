import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.url,
    this.name,
    this.size = 48,
    this.userId,
  });

  final String url;
  final String? name;
  final double size;
  final String? userId;

  static const _avatarColors = [
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // violet
    Color(0xFF0EA5E9), // sky
    Color(0xFF14B8A6), // teal
    Color(0xFF10B981), // emerald
    Color(0xFFF43F5E), // rose
    Color(0xFFEC4899), // pink
    Color(0xFFF97316), // orange
    Color(0xFF06B6D4), // cyan
    Color(0xFF64748B), // slate
  ];

  Color _backgroundColor() {
    final key = (userId?.trim().isNotEmpty == true ? userId : name)?.trim();
    if (key == null || key.isEmpty) {
      return _avatarColors.first;
    }

    final hash = key.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _avatarColors[hash % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final child = url.isEmpty ? _placeholder() : _networkImage();

    if (userId != null && userId!.isNotEmpty) {
      return GestureDetector(
        onTap: () => Get.toNamed(
          AppConstants.routes.teamMemberProfile,
          arguments: {'userId': userId},
        ),
        child: child,
      );
    }
    return child;
  }

  String? get _initial {
    final value = name?.trim();
    if (value == null || value.isEmpty) return null;
    return value[0].toUpperCase();
  }

  Widget _placeholder() {
    final initial = _initial;
    final backgroundColor = _backgroundColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      alignment: Alignment.center,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : Icon(
              Icons.person_outline,
              size: size * 0.5,
              color: Colors.white,
            ),
    );
  }

  Widget _networkImage() {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }
}
