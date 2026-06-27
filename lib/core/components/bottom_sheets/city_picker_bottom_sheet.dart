import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_places_flutter/model/place_type.dart';

import '../../../components/shared/location_autocomplete_field.dart';
import '../../config/constants.dart';
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Obx(() {
            final isDetecting = settings.isDetectingCityLocation.value;
            final screenHeight = MediaQuery.sizeOf(ctx).height;
            final keyboardHeight = MediaQuery.viewInsetsOf(ctx).bottom;
            final maxHeight =
                (screenHeight * 0.85 - keyboardHeight).clamp(280.0, screenHeight);
            final sheetHeight =
                keyboardHeight > 0 ? maxHeight : screenHeight * 0.55;

            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: SizedBox(
                height: sheetHeight.clamp(280.0, maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        onClear: isDetecting
                            ? null
                            : () async {
                                await settings.clearCityLocation();
                                onChanged?.call();
                              },
                      ),
                      const SizedBox(height: 16),
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
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: AbsorbPointer(
                            absorbing: isDetecting,
                            child: Opacity(
                              opacity: isDetecting ? 0.6 : 1,
                              child: LocationAutocompleteField(
                                controller: settings.cityController,
                                labelText: 'City',
                                hintText: 'Search city...',
                                countries: const ['in'],
                                placeType: PlaceType.cities,
                                onLocationSelected: (location) async {
                                  if (isDetecting) return;
                                  await settings.setCityLocationFromSelected(
                                    location,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

Widget _buildHeader({required VoidCallback? onClear}) {
  return Column(
    children: [
      Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Choose city',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(AppColors.primaryColor)),
            ),
          ),
        ],
      ),
    ],
  );
}
