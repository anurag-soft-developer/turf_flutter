import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/shared/avatar_image_input.dart';
import '../../components/shared/location_autocomplete_field.dart';
import '../../components/create_turf/section_container.dart';
import '../../core/models/media_upload_models.dart';
import '../../components/create_turf/styled_text_field.dart';
import '../../core/config/constants.dart';
import '../../rankings/widgets/rank_sport_filter.dart';
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
        child: controller.isEditing
            ? _EditTeamBody(controller: controller)
            : _CreateTeamStepper(controller: controller),
      ),
    );
  }
}

// ── Create mode (stepper) ─────────────────────────────────────────────────────

class _CreateTeamStepper extends StatelessWidget {
  final AddTeamController controller;

  const _CreateTeamStepper({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => _CompactStepHeader(
            currentStep: controller.currentStep.value,
            onStepTap: (step) {
              if (step < controller.currentStep.value) {
                controller.currentStep.value = step;
              }
            },
          ),
        ),
        Expanded(
          child: Obx(() {
            final step = controller.currentStep.value;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: step == 0
                  ? _SportTypeStep(controller: controller)
                  : _CreateDetailsStep(controller: controller),
            );
          }),
        ),
        _CreateStepBottomBar(controller: controller),
      ],
    );
  }
}

class _CompactStepHeader extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTap;

  const _CompactStepHeader({
    required this.currentStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            _CompactStepChip(
              index: 0,
              label: 'Sport',
              isActive: currentStep >= 0,
              isComplete: currentStep > 0,
              onTap: () => onStepTap(0),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  decoration: BoxDecoration(
                    color: currentStep > 0
                        ? const Color(AppColors.primaryColor)
                        : const Color(AppColors.dividerColor),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            _CompactStepChip(
              index: 1,
              label: 'Details',
              isActive: currentStep >= 1,
              isComplete: false,
              onTap: () => onStepTap(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStepChip extends StatelessWidget {
  final int index;
  final String label;
  final bool isActive;
  final bool isComplete;
  final VoidCallback onTap;

  const _CompactStepChip({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(AppColors.primaryColor)
        : const Color(AppColors.textSecondaryColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(AppColors.primaryColor)
                    : Colors.transparent,
                border: Border.all(color: color, width: 1.5),
              ),
              child: isComplete
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : color,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(AppColors.textColor)
                    : const Color(AppColors.textSecondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateStepBottomBar extends StatelessWidget {
  final AddTeamController controller;

  const _CreateStepBottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Obx(() {
            final step = controller.currentStep.value;
            if (step == 0) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.currentStep.value = 1,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: const Color(AppColors.primaryColor),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.currentStep.value = 0,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(AppColors.primaryColor),
                      foregroundColor: Colors.white,
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
                        : const Text(
                            'Create Team',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _SportTypeStep extends StatelessWidget {
  final AddTeamController controller;

  const _SportTypeStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What sport does your team play?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick the primary sport for this team. This can’t be changed later.',
          style: TextStyle(
            fontSize: 14,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        const SizedBox(height: 20),
        Obx(
          () {
            final sport = controller.sportType.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => SportFilterPicker.showSheet(
                  context: context,
                  value: sport,
                  sports: TeamSportType.values,
                  sheetTitle: 'Select sport',
                  searchable: true,
                  onChanged: (v) => controller.sportType.value = v,
                ),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(
                        AppColors.primaryColor,
                      ).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            AppColors.primaryColor,
                          ).withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          sport.icon,
                          color: const Color(AppColors.primaryColor),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected sport',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              teamSportLabel(sport),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(AppColors.textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CreateDetailsStep extends StatelessWidget {
  final AddTeamController controller;

  const _CreateDetailsStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarImageInput(
          imageUrls: controller.logoImages,
          label: 'Team Logo',
          placeholderIcon: Icons.shield_outlined,
          uploadPurpose: MediaUploadPurpose.teamMedia,
          allowPasteUrl: true,
          deleteRemoteOnRemove: !controller.isEditing,
          onDeferredRemoteRemoval: controller.queueDeferredRemoteImageDeletion,
          onChange: (_) {},
          radius: 52,
        ),
        const SizedBox(height: 20),
        _BasicInfoSection(controller: controller, compact: true),
      ],
    );
  }
}

// ── Edit mode (all sections, no stepper) ──────────────────────────────────────

class _EditTeamBody extends StatelessWidget {
  final AddTeamController controller;

  const _EditTeamBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarImageInput(
            imageUrls: controller.logoImages,
            label: 'Team Logo',
            placeholderIcon: Icons.shield_outlined,
            uploadPurpose: MediaUploadPurpose.teamMedia,
            allowPasteUrl: true,
            deleteRemoteOnRemove: !controller.isEditing,
            onDeferredRemoteRemoval: controller.queueDeferredRemoteImageDeletion,
            onChange: (_) {},
            radius: 52,
          ),
          const SizedBox(height: 24),
          _BasicInfoSection(controller: controller, compact: false),
          const SizedBox(height: 24),
          _ScheduleSection(controller: controller),
          const SizedBox(height: 24),
          _SocialLinksSection(controller: controller),
          const SizedBox(height: 24),
          _SubmitButton(controller: controller),
        ],
      ),
    );
  }
}

// ── Basic Info ────────────────────────────────────────────────────────────────

class _BasicInfoSection extends StatelessWidget {
  final AddTeamController controller;
  final bool compact;

  const _BasicInfoSection({
    required this.controller,
    this.compact = false,
  });

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
        if (!compact) ...[
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
          _NullableDropdown<TeamGenderCategory>(
            label: 'Gender Category',
            value: controller.genderCategory,
            items: TeamGenderCategory.values,
            itemLabel: (g) => g.name.capitalizeFirst!,
            onChanged: (v) => controller.genderCategory.value = v,
          ),
        ],
        const SizedBox(height: 16),
        LocationAutocompleteField(
          controller: controller.addressController,
          labelText: 'City',
          hintText: 'Search your team location...',
          countries: const ['in'],
          onLocationSelected: controller.onLocationSelected,
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
                : const Text(
                    'Save Changes',
                    style: TextStyle(
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
