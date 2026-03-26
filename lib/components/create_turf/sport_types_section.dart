import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_turf_controller.dart';
import '../../config/constants.dart';
import 'section_container.dart';

class SportTypesSection extends StatelessWidget {
  const SportTypesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Sport Types',
      icon: Icons.sports_soccer,
      children: [
        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.availableSportTypes.map((sport) {
              final isSelected = controller.selectedSportTypes.contains(sport);
              return FilterChip(
                label: Text(sport),
                selected: isSelected,
                onSelected: (selected) => controller.toggleSportType(sport),
                selectedColor: const Color(
                  AppColors.primaryColor,
                ).withValues(alpha: .2),
                backgroundColor: Colors.grey[100],
                checkmarkColor: const Color(AppColors.primaryColor),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(AppColors.primaryColor)
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          );
        }),
        Obx(
          () => controller.selectedSportTypes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Please select at least one sport type',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
