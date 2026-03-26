import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/create_turf/location_section.dart';
import '../../controllers/create_turf_controller.dart';
import 'section_container.dart';
import 'styled_text_field.dart';

class BasicInfoSection extends StatelessWidget {
  const BasicInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Basic Information',
      icon: Icons.info,
      children: [
        TurfFormField(
          controller: controller.nameController,
          labelText: 'Turf Name *',
          hintText: 'Enter turf name',
          validator: (value) => controller.validateRequired(value, 'Turf name'),
        ),
        const SizedBox(height: 16),
        TurfFormField(
          controller: controller.descriptionController,
          labelText: 'Description *',
          hintText: 'Describe your turf',
          autoExpand: true,
          minLines: 2,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          validator: (value) =>
              controller.validateRequired(value, 'Description'),
        ),
        const SizedBox(height: 16),
        // TextFormField(
        //   controller: controller.slotBufferController,
        //   style: const TextStyle(color: Colors.black87),
        //   decoration: const InputDecoration(
        //     labelText: 'Slot Buffer (minutes)',
        //     hintText: 'Buffer time between bookings',
        //     border: OutlineInputBorder(),
        //     labelStyle: TextStyle(color: Colors.black87),
        //     filled: true,
        //     fillColor: Colors.white,
        //   ),
        //   keyboardType: TextInputType.number,
        //   validator: (value) =>
        //       controller.validateNumber(value, 'Slot buffer', min: 0),
        // ),
        TurfFormField(
          controller: controller.basePriceController,
          labelText: 'Base Price per Hour *',
          hintText: 'Enter price in ₹',
          prefixText: '₹ ',
          keyboardType: TextInputType.number,
          validator: (value) =>
              controller.validateNumber(value, 'Base price', min: 1),
        ),
        const SizedBox(height: 16),
        LocationSection(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TurfFormField(
                controller: controller.openTimeController,
                labelText: 'Opening Time *',
                hintText: 'HH:MM',
                suffixIcon: Icons.access_time,
                readOnly: true,
                onTap: () => controller.pickTime(controller.openTimeController),
                validator: controller.validateTime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TurfFormField(
                controller: controller.closeTimeController,
                labelText: 'Closing Time *',
                hintText: 'HH:MM',
                suffixIcon: Icons.access_time,
                readOnly: true,
                onTap: () =>
                    controller.pickTime(controller.closeTimeController),
                validator: controller.validateTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
