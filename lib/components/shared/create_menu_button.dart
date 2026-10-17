import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../openings/opening_manage.dart';

/// Plus menu shared by Explore and Profile.
class CreateMenuButton extends StatelessWidget {
  const CreateMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Create',
      icon: const Icon(Icons.add),
      color: Colors.white,
      onSelected: (value) => _onSelected(context, value),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'post',
          child: _CreateMenuLabel(
            icon: Icons.add_a_photo_outlined,
            label: 'New Post',
          ),
        ),
        PopupMenuItem(
          value: 'opening',
          child: _CreateMenuLabel(
            icon: Icons.campaign_outlined,
            label: 'New Opening',
          ),
        ),
        PopupMenuItem(
          value: 'tournament',
          child: _CreateMenuLabel(
            icon: Icons.emoji_events_outlined,
            label: 'Host tournament',
          ),
        ),
        PopupMenuItem(
          value: 'team',
          child: _CreateMenuLabel(
            icon: Icons.groups_outlined,
            label: 'Add team',
          ),
        ),
      ],
    );
  }

  void _onSelected(BuildContext context, String value) {
    switch (value) {
      case 'post':
        Get.toNamed(AppConstants.routes.createPost);
      case 'opening':
        openPostOpening(context);
      case 'tournament':
        Get.toNamed(AppConstants.routes.createTournament);
      case 'team':
        Get.toNamed(AppConstants.routes.addTeam);
    }
  }
}

class _CreateMenuLabel extends StatelessWidget {
  const _CreateMenuLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const color = Color(AppColors.textColor);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: color)),
      ],
    );
  }
}
