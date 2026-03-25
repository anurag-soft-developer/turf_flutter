import 'package:flutter/material.dart';
import '../../controllers/create_turf_controller.dart';
import 'section_container.dart';

class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Pricing',
      icon: Icons.attach_money,
      children: [
        TextFormField(
          controller: controller.basePriceController,
          decoration: const InputDecoration(
            labelText: 'Base Price per Hour *',
            hintText: 'Enter price in ₹',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            prefixText: '₹ ',
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              controller.validateNumber(value, 'Base price', min: 1),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.weekendSurgeController,
          decoration: const InputDecoration(
            labelText: 'Weekend Surge (0-1)',
            hintText: 'e.g., 0.2 for 20% surge',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            helperText: 'Enter decimal value (0.2 = 20% surge)',
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              controller.validateNumber(value, 'Weekend surge', min: 0),
        ),
      ],
    );
  }
}
