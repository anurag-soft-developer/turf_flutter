import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';

/// AppBar title: team avatar vs team avatar (name used for initials fallback).
class VsAppBarTitle extends StatelessWidget {
  const VsAppBarTitle({
    super.key,
    required this.leftName,
    required this.rightName,
    this.leftLogoUrl,
    this.rightLogoUrl,
  });

  final String leftName;
  final String rightName;
  final String? leftLogoUrl;
  final String? rightLogoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TeamAvatar(name: leftName, logoUrl: leftLogoUrl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        _TeamAvatar(name: rightName, logoUrl: rightLogoUrl),
      ],
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.name, this.logoUrl});

  final String name;
  final String? logoUrl;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      backgroundImage: hasLogo ? AppNetworkImage.provider(logoUrl!) : null,
      child: hasLogo
          ? null
          : Text(
              _initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
    );
  }
}
