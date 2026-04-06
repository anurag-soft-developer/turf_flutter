import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/shared/image_input.dart';
import '../../components/create_turf/section_container.dart';
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
              _TeamSettingsSection(controller: controller),
              const SizedBox(height: 24),
              _RosterSection(controller: controller),
              const SizedBox(height: 24),
              ImageInput(
                title: 'Team Logo',
                icon: Icons.shield,
                imageUrls: controller.logoImages,
                onShowOptions: controller.showLogoPickerOptions,
                onPickCamera: controller.pickLogoFromCamera,
                onPickGallery: controller.pickLogoFromGallery,
                onRemove: controller.removeLogo,
                maxImages: 1,
              ),
              const SizedBox(height: 24),
              ImageInput(
                title: 'Cover Images',
                icon: Icons.image,
                imageUrls: controller.coverImages,
                onShowOptions: controller.showCoverPickerOptions,
                onPickCamera: controller.pickCoverFromCamera,
                onPickGallery: controller.pickCoverFromGallery,
                onRemove: controller.removeCover,
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
          controller: controller.descriptionController,
          labelText: 'Description (optional)',
          hintText: 'What is your team about?',
          autoExpand: true,
          minLines: 3,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }
}

// ── Team Settings ─────────────────────────────────────────────────────────────

class _TeamSettingsSection extends StatelessWidget {
  final AddTeamController controller;

  const _TeamSettingsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Team Settings',
      icon: Icons.settings_outlined,
      children: [
        _StyledDropdown<TeamSportType>(
          label: 'Sport',
          value: controller.sportType,
          items: TeamSportType.values,
          itemLabel: teamSportLabel,
          onChanged: (v) => controller.sportType.value = v,
        ),
        const SizedBox(height: 16),
        _StyledDropdown<TeamVisibility>(
          label: 'Visibility',
          value: controller.visibility,
          items: TeamVisibility.values,
          itemLabel: teamVisibilityLabel,
          onChanged: (v) => controller.visibility.value = v,
        ),
        const SizedBox(height: 16),
        _StyledDropdown<TeamJoinMode>(
          label: 'How Players Join',
          value: controller.joinMode,
          items: TeamJoinMode.values,
          itemLabel: teamJoinModeLabel,
          onChanged: (v) => controller.joinMode.value = v,
        ),
      ],
    );
  }
}

// ── Roster ────────────────────────────────────────────────────────────────────

class _RosterSection extends StatelessWidget {
  final AddTeamController controller;

  const _RosterSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Roster',
      icon: Icons.group_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: TurfFormField(
                controller: controller.maxRosterController,
                labelText: 'Max Players *',
                hintText: '20',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Enter a positive number';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TurfFormField(
                controller: controller.maxPendingController,
                labelText: 'Max Pending Requests *',
                hintText: '10',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter 0 or more';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Styled Dropdown ───────────────────────────────────────────────────────────

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
