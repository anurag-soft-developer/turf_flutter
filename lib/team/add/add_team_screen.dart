import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:google_places_flutter/model/place_type.dart';
import '../../components/shared/image_input.dart';
import '../../components/shared/location_autocomplete_field.dart';
import '../../components/create_turf/section_container.dart';
import '../../core/models/media_upload_models.dart';
import '../../components/create_turf/styled_text_field.dart';
import '../../core/config/constants.dart';
import '../model/team_model.dart';
import '../utils/team_ui.dart';
import 'add_team_controller.dart';

class AddTeamScreen extends StatelessWidget {
  const AddTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddTeamController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text(
          controller.isEditing ? 'Edit Team' : 'Create Team',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(AppColors.textColor),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(AppColors.textColor)),
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BasicInfoSection(controller: controller),
              const SizedBox(height: 24),
              // _TeamSettingsSection(controller: controller),
              // const SizedBox(height: 24),
              _ScheduleSection(controller: controller),
              const SizedBox(height: 24),
              _SocialLinksSection(controller: controller),
              const SizedBox(height: 24),
              // _TagsSection(controller: controller),
              // const SizedBox(height: 24),
              // _PinnedNoticesSection(controller: controller),
              // const SizedBox(height: 24),
              // _RosterSection(controller: controller),
              // const SizedBox(height: 24),
              ImageInput(
                title: 'Team Logo',
                icon: Icons.shield,
                imageUrls: controller.logoImages,
                onChange: (_) {},
                maxImages: 1,
                uploadPurpose: MediaUploadPurpose.teamMedia,
                allowPasteUrl: true,
                deleteRemoteOnRemove: !controller.isEditing,
                onDeferredRemoteRemoval:
                    controller.queueDeferredRemoteImageDeletion,
              ),
              const SizedBox(height: 24),
              ImageInput(
                title: 'Cover Images',
                icon: Icons.image,
                imageUrls: controller.coverImages,
                onChange: (_) {},
                uploadPurpose: MediaUploadPurpose.teamMedia,
                allowPasteUrl: true,
                deleteRemoteOnRemove: !controller.isEditing,
                onDeferredRemoteRemoval:
                    controller.queueDeferredRemoteImageDeletion,
              ),
              const SizedBox(height: 24),
              _SubmitButton(controller: controller),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Basic Info ────────────────────────────────────────────────────────────────

class _BasicInfoSection extends StatelessWidget {
  final AddTeamController controller;

  const _BasicInfoSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Basic Information',
      icon: Icons.info_outline,
      children: [
        TurfFormField(
          controller: controller.nameController,
          labelText: 'Team Name *',
          hintText: 'e.g. Night Hawks FC',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter a team name';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TurfFormField(
          controller: controller.shortNameController,
          labelText: 'Short Name',
          hintText: 'e.g. NHF',
        ),
        const SizedBox(height: 16),
        TurfFormField(
          controller: controller.taglineController,
          labelText: 'Tagline',
          hintText: 'e.g. We play to win!',
        ),
        const SizedBox(height: 16),
        TurfFormField(
          controller: controller.descriptionController,
          labelText: 'Description',
          hintText: 'What is your team about?',
          autoExpand: true,
          minLines: 3,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 16),
        TurfFormField(
          controller: controller.foundedYearController,
          labelText: 'Founded Year',
          hintText: 'e.g. 2020',
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final n = int.tryParse(v.trim());
            if (n == null || n < 1800 || n > DateTime.now().year) {
              return 'Enter a valid year';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        if (!controller.isEditing) ...[
          _StyledDropdown<TeamSportType>(
            label: 'Sport',
            value: controller.sportType,
            items: TeamSportType.values,
            itemLabel: teamSportLabel,
            onChanged: (v) => controller.sportType.value = v,
          ),
          const SizedBox(height: 16),
        ],
        _NullableDropdown<TeamGenderCategory>(
          label: 'Gender Category',
          value: controller.genderCategory,
          items: TeamGenderCategory.values,
          itemLabel: (g) => g.name.capitalizeFirst!,
          onChanged: (v) => controller.genderCategory.value = v,
        ),
        const SizedBox(height: 16),
        LocationAutocompleteField(
          controller: controller.addressController,
          labelText: 'City',
          hintText: 'Search your team location...',
          countries: const ['in'],
          // placeType: PlaceType.cities,
          onLocationSelected: (address, latitude, longitude) {
            controller.addressController.text = address;
            controller.latController.text = latitude?.toString() ?? '';
            controller.lngController.text = longitude?.toString() ?? '';
          },
        ),
      ],
    );
  }
}

// ── Schedule & Preferences ────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final AddTeamController controller;

  const _ScheduleSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Schedule & Preferences',
      icon: Icons.schedule_outlined,
      children: [
        const Text(
          'Preferred Play Days',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TeamDayOfWeek.values.map((day) {
              final selected = controller.preferredPlayDays.contains(day);
              return ChoiceChip(
                label: Text(_dayShortLabel(day)),
                selected: selected,
                onSelected: (_) => controller.toggleDay(day),
                selectedColor: const Color(AppColors.primaryColor),
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(AppColors.textColor),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selected
                        ? const Color(AppColors.primaryColor)
                        : Colors.grey.shade300,
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _NullableDropdown<TeamPreferredTimeSlot>(
          label: 'Preferred Time Slot',
          value: controller.preferredTimeSlot,
          items: TeamPreferredTimeSlot.values,
          itemLabel: _timeSlotLabel,
          onChanged: (v) => controller.preferredTimeSlot.value = v,
        ),
      ],
    );
  }

  static String _dayShortLabel(TeamDayOfWeek d) {
    return switch (d) {
      TeamDayOfWeek.monday => 'Mon',
      TeamDayOfWeek.tuesday => 'Tue',
      TeamDayOfWeek.wednesday => 'Wed',
      TeamDayOfWeek.thursday => 'Thu',
      TeamDayOfWeek.friday => 'Fri',
      TeamDayOfWeek.saturday => 'Sat',
      TeamDayOfWeek.sunday => 'Sun',
    };
  }

  static String _timeSlotLabel(TeamPreferredTimeSlot t) {
    return switch (t) {
      TeamPreferredTimeSlot.morning => 'Morning',
      TeamPreferredTimeSlot.afternoon => 'Afternoon',
      TeamPreferredTimeSlot.evening => 'Evening',
    };
  }
}

// ── Social Links ──────────────────────────────────────────────────────────────

class _SocialLinksSection extends StatelessWidget {
  final AddTeamController controller;

  const _SocialLinksSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Social Links',
      icon: Icons.link,
      children: [
        TurfFormField(
          controller: controller.instagramController,
          labelText: 'Instagram',
          hintText: 'https://instagram.com/yourteam',
          prefixIcon: Icons.camera_alt_outlined,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TurfFormField(
          controller: controller.twitterController,
          labelText: 'Twitter / X',
          hintText: 'https://x.com/yourteam',
          prefixIcon: Icons.alternate_email,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TurfFormField(
          controller: controller.facebookController,
          labelText: 'Facebook',
          hintText: 'https://facebook.com/yourteam',
          prefixIcon: Icons.facebook_outlined,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TurfFormField(
          controller: controller.youtubeController,
          labelText: 'YouTube',
          hintText: 'https://youtube.com/@yourteam',
          prefixIcon: Icons.play_circle_outline,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

// ── Tags ──────────────────────────────────────────────────────────────────────

// class _TagsSection extends StatelessWidget {
//   final AddTeamController controller;

//   const _TagsSection({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return SectionContainer(
//       title: 'Tags',
//       icon: Icons.tag,
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: TurfFormField(
//                 controller: controller.tagInputController,
//                 labelText: 'Add a tag',
//                 hintText: 'e.g. competitive',
//                 onFieldSubmitted: (_) => controller.addTag(),
//               ),
//             ),
//             const SizedBox(width: 10),
//             IconButton.filled(
//               onPressed: controller.addTag,
//               icon: const Icon(Icons.add, size: 20),
//               style: IconButton.styleFrom(
//                 backgroundColor: const Color(AppColors.primaryColor),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         Obx(
//           () => controller.tags.isEmpty
//               ? const SizedBox.shrink()
//               : Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: controller.tags
//                       .map(
//                         (tag) => Chip(
//                           label: Text(
//                             '#$tag',
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Color(AppColors.primaryColor),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           backgroundColor: const Color(
//                             AppColors.primaryColor,
//                           ).withValues(alpha: 0.08),
//                           deleteIcon: const Icon(Icons.close, size: 16),
//                           deleteIconColor: const Color(AppColors.primaryColor),
//                           onDeleted: () => controller.removeTag(tag),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                             side: BorderSide(
//                               color: const Color(
//                                 AppColors.primaryColor,
//                               ).withValues(alpha: 0.2),
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//                 ),
//         ),
//       ],
//     );
//   }
// }

// ── Pinned Notices ────────────────────────────────────────────────────────────

// class _PinnedNoticesSection extends StatelessWidget {
//   final AddTeamController controller;

//   const _PinnedNoticesSection({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return SectionContainer(
//       title: 'Pinned Notices',
//       icon: Icons.push_pin_outlined,
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: TurfFormField(
//                 controller: controller.noticeInputController,
//                 labelText: 'Add a notice',
//                 hintText: 'e.g. Practice every Saturday 5 PM',
//                 onFieldSubmitted: (_) => controller.addNotice(),
//               ),
//             ),
//             const SizedBox(width: 10),
//             IconButton.filled(
//               onPressed: controller.addNotice,
//               icon: const Icon(Icons.add, size: 20),
//               style: IconButton.styleFrom(
//                 backgroundColor: const Color(AppColors.primaryColor),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         Obx(
//           () => controller.pinnedNotices.isEmpty
//               ? const SizedBox.shrink()
//               : Column(
//                   children: [
//                     for (int i = 0; i < controller.pinnedNotices.length; i++)
//                       Container(
//                         margin: const EdgeInsets.only(bottom: 8),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 10,
//                         ),
//                         decoration: BoxDecoration(
//                           color: const Color(
//                             AppColors.accentColor,
//                           ).withValues(alpha: 0.06),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: const Color(
//                               AppColors.accentColor,
//                             ).withValues(alpha: 0.15),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.push_pin,
//                               size: 16,
//                               color: const Color(AppColors.accentColor),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: Text(
//                                 controller.pinnedNotices[i],
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   color: Color(AppColors.textColor),
//                                 ),
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: () => controller.removeNotice(i),
//                               child: Icon(
//                                 Icons.close,
//                                 size: 18,
//                                 color: const Color(
//                                   AppColors.textSecondaryColor,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//         ),
//       ],
//     );
//   }
// }

// ── Join Requests ─────────────────────────────────────────────────────────────

// class _RosterSection extends StatelessWidget {
//   final AddTeamController controller;

//   const _RosterSection({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return SectionContainer(
//       title: 'Join Requests',
//       icon: Icons.hourglass_empty_outlined,
//       children: [
//         TurfFormField(
//           controller: controller.maxPendingController,
//           labelText: 'Max pending join requests *',
//           hintText: '0–1000',
//           keyboardType: TextInputType.number,
//           validator: (v) {
//             final n = int.tryParse(v ?? '');
//             if (n == null || n < 0 || n > 1000) {
//               return 'Enter 0–1000';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }
// }

// ── Styled Dropdown (required value) ──────────────────────────────────────────

class _StyledDropdown<T> extends StatelessWidget {
  final String label;
  final Rx<T> value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T) onChanged;

  const _StyledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: DropdownButtonFormField<T>(
          initialValue: value.value,
          isExpanded: false,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            labelStyle: const TextStyle(color: Colors.black87),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          dropdownColor: Colors.white,
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(itemLabel(s))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Nullable Dropdown (optional value with "None" option) ─────────────────────

class _NullableDropdown<T> extends StatelessWidget {
  final String label;
  final Rxn<T> value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const _NullableDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: DropdownButtonFormField<T?>(
          initialValue: value.value,
          isExpanded: false,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            labelStyle: const TextStyle(color: Colors.black87),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem<T?>(
              value: null,
              child: const Text(
                'Not specified',
                style: TextStyle(color: Colors.black45),
              ),
            ),
            ...items.map(
              (s) => DropdownMenuItem<T?>(value: s, child: Text(itemLabel(s))),
            ),
          ],
          onChanged: (v) => onChanged(v),
        ),
      ),
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final AddTeamController controller;

  const _SubmitButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.isSubmitting.value ? null : controller.submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            child: controller.isSubmitting.value
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    controller.isEditing ? 'Save Changes' : 'Create Team',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
