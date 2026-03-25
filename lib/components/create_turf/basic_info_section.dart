import 'package:flutter/material.dart';
import '../../controllers/create_turf_controller.dart';
import 'section_container.dart';

class BasicInfoSection extends StatelessWidget {
  const BasicInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Basic Information',
      icon: Icons.info,
      children: [
        TextFormField(
          controller: controller.nameController,
          decoration: const InputDecoration(
            labelText: 'Turf Name *',
            hintText: 'Enter turf name',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) => controller.validateRequired(value, 'Turf name'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Describe your turf',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 3,
          validator: (value) =>
              controller.validateRequired(value, 'Description'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.slotBufferController,
          decoration: const InputDecoration(
            labelText: 'Slot Buffer (minutes)',
            hintText: 'Buffer time between bookings',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              controller.validateNumber(value, 'Slot buffer', min: 0),
        ),
      ],
    );
  }
}
