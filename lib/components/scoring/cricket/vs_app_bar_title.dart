import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';

/// AppBar title showing two team names separated by a "VS" pill.
class VsAppBarTitle extends StatelessWidget {
  const VsAppBarTitle({
    super.key,
    required this.leftName,
    required this.rightName,
    required this.maxNameWidth,
  });

  final String leftName;
  final String rightName;
  final double maxNameWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxNameWidth),
          child: Text(
            leftName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Color(AppColors.primaryColor),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxNameWidth),
          child: Text(
            rightName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
