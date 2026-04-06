import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'create_turf_controller.dart';
import '../../core/config/constants.dart';
import '../../components/create_turf/basic_info_section.dart';
import '../../components/shared/image_input.dart';
import '../../components/create_turf/sport_types_section.dart';
import '../../components/create_turf/amenities_section.dart';
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
              const SportTypesSection(),
              const SizedBox(height: 24),
              const AmenitiesSection(),
              const SizedBox(height: 24),
              ImageInput(
                imageUrls: controller.imageUrls,
                onShowOptions: controller.showImagePickerOptions,
                onPickCamera: controller.pickImageFromCamera,
                onPickGallery: controller.pickImageFromGallery,
                onRemove: controller.removeImageUrl,
                requireAtLeastOne: true,
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
