import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_turf_controller.dart';
import 'section_container.dart';

class AmenitiesSection extends StatelessWidget {
  const AmenitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Amenities',
      icon: Icons.business_center,
      children: [
        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.availableAmenities.map((amenity) {
              final isSelected = controller.selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity),
                selected: isSelected,
                onSelected: (selected) => controller.toggleAmenity(amenity),
                selectedColor: Colors.green.withValues(alpha: .2),
                backgroundColor: Colors.grey[100],
                checkmarkColor: Colors.green,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.green[700] : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
