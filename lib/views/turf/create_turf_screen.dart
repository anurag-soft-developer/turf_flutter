import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_turf_controller.dart';
import '../../config/constants.dart';
import '../../components/create_turf/basic_info_section.dart';
import '../../components/create_turf/images_section.dart';
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
            children: const [
              BasicInfoSection(),
              SizedBox(height: 24),
              DimensionsSection(),
              SizedBox(height: 24),
              SportTypesSection(),
              SizedBox(height: 24),
              AmenitiesSection(),
              SizedBox(height: 24),
              ImagesSection(),
              SizedBox(height: 24),
              SubmitButton(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
