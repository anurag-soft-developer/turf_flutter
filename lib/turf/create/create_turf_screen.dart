import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'create_turf_controller.dart';
import '../../core/config/constants.dart';
import '../../core/models/media_upload_models.dart';
import '../../components/create_turf/basic_info_section.dart';
import '../../components/shared/image_input.dart';
import '../../components/shared/selectable_chip_input.dart';
import '../../components/create_turf/dimensions_section.dart';
import '../../components/create_turf/submit_button.dart';

class CreateTurfScreen extends StatelessWidget {
  const CreateTurfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.formTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(AppColors.textColor)),
        actions: [
          TextButton(
            onPressed: () => controller.resetForm(),
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(AppColors.primaryColor)),
            ),
          ),
        ],
      ),
      body: Form(
        key: CreateTurfController.instance.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BasicInfoSection(),
              const SizedBox(height: 24),
              const DimensionsSection(),
              const SizedBox(height: 24),
              SelectableChipInput(
                title: 'Sport Types',
                icon: Icons.sports_soccer,
                options: controller.availableSportTypes,
                selected: controller.selectedSportTypes,
                onToggle: controller.toggleSportType,
                emptySelectionWarning: 'Please select at least one sport type',
              ),
              const SizedBox(height: 24),
              SelectableChipInput(
                title: 'Amenities',
                icon: Icons.business_center,
                options: controller.availableAmenities,
                selected: controller.selectedAmenities,
                onToggle: controller.toggleAmenity,
              ),
              const SizedBox(height: 24),
              Obx(
                () => ImageInput(
                  imageUrls: controller.imageUrls,
                  minImages: 1,
                  uploadPurpose: MediaUploadPurpose.turfMedia,
                  allowPasteUrl: true,
                  deleteRemoteOnRemove: !controller.isEditMode.value,
                  onDeferredRemoteRemoval:
                      controller.queueDeferredRemoteImageDeletion,
                ),
              ),
              const SizedBox(height: 24),
              const SubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
