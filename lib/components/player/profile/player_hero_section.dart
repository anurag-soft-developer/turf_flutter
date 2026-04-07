import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';

class PlayerHeroSection extends StatelessWidget {
  const PlayerHeroSection({super.key, required this.helper});

  final UserFieldInstance helper;

  @override
  Widget build(BuildContext context) {
    final model = helper.getModel();
    final title = helper.getDisplayName();

    return Container(
      constraints: BoxConstraints(
        minHeight: 280,
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(AppColors.primaryColor),
            const Color(AppColors.primaryColor).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60), // Space for app bar
              // Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage:
                    helper.getAvatar() != null && helper.getAvatar()!.isNotEmpty
                    ? NetworkImage(helper.getAvatar()!)
                    : null,
                child: helper.getAvatar() == null || helper.getAvatar()!.isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              // Email
              if (helper.getEmail() != null) ...[
                const SizedBox(height: 2),
                Text(
                  helper.getEmail()!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Bio preview
              if (model?.bio != null && model!.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  model.bio!.length > 60
                      ? '${model.bio!.substring(0, 60)}...'
                      : model.bio!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
