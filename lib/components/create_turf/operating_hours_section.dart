import 'package:flutter/material.dart';
import '../../controllers/create_turf_controller.dart';
import 'section_container.dart';

class OperatingHoursSection extends StatelessWidget {
  const OperatingHoursSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Operating Hours',
      icon: Icons.access_time,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.openTimeController,
                decoration: const InputDecoration(
                  labelText: 'Opening Time *',
                  hintText: 'HH:MM',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => controller.pickTime(controller.openTimeController),
                validator: controller.validateTime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller.closeTimeController,
                decoration: const InputDecoration(
                  labelText: 'Closing Time *',
                  hintText: 'HH:MM',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.access_time),
                ),
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
