import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../controllers/create_turf_controller.dart';
import '../../config/env_config.dart';
import 'section_container.dart';

class LocationSection extends StatelessWidget {
  const LocationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return SectionContainer(
      title: 'Location',
      icon: Icons.location_on,
      children: [
        GooglePlaceAutoCompleteTextField(
          textEditingController: controller.addressController,
          googleAPIKey: EnvConfig.googlePlacesApiKey,
          inputDecoration: const InputDecoration(
            labelText: 'Address *',
            hintText: 'Start typing to search places...',
            suffixIcon: Icon(Icons.place),
          ),
          debounceTime: 600,
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (Prediction prediction) {
            // Auto-populate coordinates
            controller.latController.text = prediction.lat?.toString() ?? '';
            controller.lngController.text = prediction.lng?.toString() ?? '';
          },
          itemClick: (Prediction prediction) {
            controller.addressController.text = prediction.description ?? '';
          },
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 12),
      ],
    );
  }
}
