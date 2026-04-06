import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/models/user_field_instance.dart';

/// Arguments: `{'user': dynamic}` — populated [UserModel] or user id string.
class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = Get.arguments;
    dynamic userField;
    if (raw is Map<String, dynamic>) {
      userField = raw['user'];
    }

    final helper = UserFieldInstance(userField);
    final model = helper.getModel();
    final title = helper.getDisplayName();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Member profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: 0.15),
              backgroundImage:
                  helper.getAvatar() != null && helper.getAvatar()!.isNotEmpty
                  ? NetworkImage(helper.getAvatar()!)
                  : null,
              child: helper.getAvatar() == null || helper.getAvatar()!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 48,
                      color: Color(AppColors.primaryColor),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
          if (helper.getEmail() != null) ...[
            const SizedBox(height: 8),
            Text(
              helper.getEmail()!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ],
          if (model?.phone != null && model!.phone!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _infoRow(Icons.phone, model.phone!),
          ],
          if (model?.bio != null && model!.bio!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Bio',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              model.bio!,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
                height: 1.4,
              ),
            ),
          ],
          if (helper.isIdOnly) ...[
            const SizedBox(height: 24),
            Text(
              'User id: ${helper.getId() ?? '—'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Full profile details appear when the server returns a populated user object.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: const Color(AppColors.primaryColor)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Color(AppColors.textColor)),
          ),
        ),
      ],
    );
  }
}
