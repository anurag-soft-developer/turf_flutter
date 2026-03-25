import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_turf_controller.dart';
import 'section_container.dart';

class DimensionsSection extends StatelessWidget {
  const DimensionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Dimensions',
      icon: Icons.straighten,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.lengthController,
                decoration: const InputDecoration(
                  labelText: 'Length',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    controller.validateNumber(value, 'Length', min: 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller.widthController,
                decoration: const InputDecoration(
                  labelText: 'Width',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    controller.validateNumber(value, 'Width', min: 0),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<String>(
                  value: controller.selectedDimensionUnit.value,
                  underline: const SizedBox(),
                  items: controller.dimensionUnits.map((unit) {
                    return DropdownMenuItem(value: unit, child: Text(unit));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) controller.setDimensionUnit(value);
                  },
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
