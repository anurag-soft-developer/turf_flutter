import 'package:flutter/material.dart';

import 'team_logo.dart';

/// Overlapping from/to team logos (match chats, mention pickers, tags).
class MatchPairLogos extends StatelessWidget {
  const MatchPairLogos({
    super.key,
    this.leftUrl,
    this.rightUrl,
    this.size = 36,
    this.compact = false,
  });

  final String? leftUrl;
  final String? rightUrl;
  final double size;

  /// Tighter overlap + thinner ring for dense rows (chat inbox / app bar).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final overlapFactor = compact ? 0.30 : 0.42;
    final borderWidth = compact ? 1.5 : 2.0;
    final overlap = size * overlapFactor;

    return SizedBox(
      width: overlap + size,
      height: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: TeamLogo(url: leftUrl ?? '', size: size),
          ),
          Positioned(
            left: overlap,
            top: 0,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TeamLogo(url: rightUrl ?? '', size: size),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: borderWidth,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
