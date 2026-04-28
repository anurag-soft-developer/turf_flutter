import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_places_flutter/model/place_type.dart';

import '../../../components/shared/location_autocomplete_field.dart';
import '../../../settings/settings_controller.dart';

class CityPickerBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required SettingsController settings,
    VoidCallback? onChanged,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Obx(() {
            final isDetecting = settings.isDetectingCityLocation.value;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.55,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      const Text(
                        'Choose city',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isDetecting) ...[
                        const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: isDetecting
                            ? null
                            : () async {
                                await settings.detectCurrentCityLocation(
                                  requestPermission: true,
                                );
                                onChanged?.call();
                                if (!ctx.mounted) return;
                                if (Navigator.of(ctx).canPop()) {
                                  Navigator.of(ctx).pop();
                                }
                              },
                        icon: isDetecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          isDetecting
                              ? 'Detecting current location...'
                              : 'Detect current location',
                        ),
                      ),
                      const SizedBox(height: 12),
                      AbsorbPointer(
                        absorbing: isDetecting,
                        child: Opacity(
                          opacity: isDetecting ? 0.6 : 1,
                          child: LocationAutocompleteField(
                            controller: settings.cityController,
                            labelText: 'City',
                            hintText: 'Search city...',
                            countries: const ['in'],
                            placeType: PlaceType.cities,
                            onLocationSelected:
                                (address, latitude, longitude) async {
                                  if (isDetecting) return;
                                  if (latitude == null || longitude == null) {
                                    return;
                                  }
                                  await settings.setCityLocation(
                                    address: address,
                                    latitude: latitude,
                                    longitude: longitude,
                                  );
                                  onChanged?.call();
                                  if (ctx.mounted &&
                                      Navigator.of(ctx).canPop()) {
                                    Navigator.of(ctx).pop();
                                  }
                                },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isDetecting
                            ? null
                            : () async {
                                await settings.clearCityLocation();
                                onChanged?.call();
                                if (ctx.mounted && Navigator.of(ctx).canPop()) {
                                  Navigator.of(ctx).pop();
                                }
                              },
                        child: const Text('Clear city filter'),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
