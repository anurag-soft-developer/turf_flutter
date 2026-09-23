import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';

import '../../components/shared/app_network_image.dart';
import '../../core/config/constants.dart';
import '../../core/media/local_image_pipeline.dart';
import '../../core/models/media_upload_models.dart';
import '../../core/services/media_upload_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../team/model/team_model.dart';
import 'util/announced_player_roles_helpers.dart';

/// Draft guest collected in the UI; posted immediately via [ManageAnnouncedPlayersController.addGuest].
class GuestDraft {
  const GuestDraft({
    required this.localId,
    required this.name,
    this.avatar,
    required this.role,
    this.isSubstitute = false,
  });

  /// Client-only id for C/VC and remove before save.
  final String localId;
  final String name;
  final String? avatar;
  final AnnouncedPlayerRole role;
  final bool isSubstitute;

  AnnouncedPlayerCreatePayload toCreatePayload({
    bool isCaption = false,
    bool isWiseCaption = false,
  }) {
    return AnnouncedPlayerCreatePayload(
      name: name,
      avatar: avatar,
      isGuest: true,
      isSubstitute: isSubstitute,
      role: role,
      isCaption: isCaption,
      isWiseCaption: isWiseCaption,
    );
  }
}

/// Collects walk-in guest details without writing to the backend.
Future<GuestDraft?> showAddGuestSheet({
  required BuildContext context,
  required TeamSportType sport,
}) {
  return showModalBottomSheet<GuestDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(AppColors.backgroundColor),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _AddGuestSheet(sport: sport),
  );
}

class _AddGuestSheet extends HookWidget {
  const _AddGuestSheet({required this.sport});

  final TeamSportType sport;

  static const _fieldDecoration = InputDecoration(
    border: OutlineInputBorder(),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final roleOptions = useMemoized(
      () => announcedRolesForSport(sport),
      [sport],
    );
    final nameController = useTextEditingController();
    final role = useState(defaultAnnouncedRoleForSport(sport));
    final isSubstitute = useState(false);
    final avatarUrl = useState<String?>(null);
    final uploading = useState(false);
    final picker = useMemoized(ImagePicker.new);

    useEffect(() {
      if (roleOptions.contains(role.value)) return null;
      role.value = roleOptions.first;
      return null;
    }, [roleOptions]);

    Future<void> pickAvatar(ImageSource source) async {
      final file = await ImageSourcePicker.pickSingle(
        picker: picker,
        source: source,
      );
      if (file == null || !context.mounted) return;
      uploading.value = true;
      try {
        final uploaded = await MediaUploadService.instance.uploadLocalFile(
          file: File(file.path),
          purpose: MediaUploadPurpose.avatar,
          onProgress: (_) {},
        );
        if (uploaded != null) {
          avatarUrl.value = uploaded.fileUrl;
        }
      } catch (e) {
        AppSnackbar.error(
          title: 'Upload failed',
          message: e.toString(),
        );
      } finally {
        uploading.value = false;
      }
    }

    void confirm() {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        AppSnackbar.info(title: 'Name required', message: 'Enter a guest name.');
        return;
      }
      if (uploading.value) return;
      Navigator.pop(
        context,
        GuestDraft(
          localId: 'pending_${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          avatar: avatarUrl.value,
          role: role.value,
          isSubstitute: isSubstitute.value,
        ),
      );
    }

    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Add guest',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a player who is not on your roster.',
              style: TextStyle(
                fontSize: 13,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: uploading.value
                    ? null
                    : () => ImageSourcePicker.showSourceSheet(
                        title: 'Guest photo',
                        onCamera: () => pickAvatar(ImageSource.camera),
                        onGallery: () => pickAvatar(ImageSource.gallery),
                        isMounted: () => context.mounted,
                      ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.1),
                  backgroundImage:
                      avatarUrl.value != null && avatarUrl.value!.isNotEmpty
                      ? AppNetworkImage.provider(avatarUrl.value!)
                      : null,
                  child: uploading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (avatarUrl.value == null || avatarUrl.value!.isEmpty)
                      ? const Icon(
                          Icons.add_a_photo_outlined,
                          color: Color(AppColors.primaryColor),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration.copyWith(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AnnouncedPlayerRole>(
              key: ValueKey(role.value),
              initialValue: role.value,
              isExpanded: true,
              decoration: _fieldDecoration.copyWith(labelText: 'Role'),
              items: [
                for (final option in roleOptions)
                  DropdownMenuItem(
                    value: option,
                    child: Text(announcedRoleLabelForSport(sport, option)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) role.value = v;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Substitute'),
              value: isSubstitute.value,
              onChanged: (v) => isSubstitute.value = v,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: uploading.value ? null : confirm,
              child: const Text('Add guest'),
            ),
          ],
        ),
      ),
    );
  }
}
