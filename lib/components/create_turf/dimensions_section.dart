import 'package:flutter/material.dart';
import '../../controllers/create_turf_controller.dart';
import 'section_container.dart';
import 'styled_text_field.dart';

class DimensionsSection extends StatelessWidget {
  const DimensionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Dimensions (Meters)',
      icon: Icons.straighten,
      children: [
        Row(
          children: [
            Expanded(
              child: TurfFormField(
                controller: controller.lengthController,
                labelText: 'Length',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    controller.validateNumber(value, 'Length', min: 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TurfFormField(
                controller: controller.widthController,
                labelText: 'Width',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    controller.validateNumber(value, 'Width', min: 0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
