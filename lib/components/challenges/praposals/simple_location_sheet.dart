import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

import '../../../core/config/constants.dart';
import '../../../core/config/env_config.dart';
import '../../../core/models/location_model.dart';
import '../../../core/utils/place_address_components.dart';

/// Lightweight place search sheet. Returns a [LocationModel] on selection.
///
/// Uses nearly full screen height so Google Places overlay suggestions
/// have room below the field instead of clipping off-screen.
class SimpleLocationSheet extends HookWidget {
  const SimpleLocationSheet({super.key, this.initialAddress});

  final String? initialAddress;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialAddress ?? '');
    final focusNode = useFocusNode();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) focusNode.requestFocus();
      });
      return null;
    }, const []);

    Future<void> onPrediction(Prediction prediction) async {
      final address = prediction.description?.trim() ?? '';
      final latitude = double.tryParse(prediction.lat ?? '');
      final longitude = double.tryParse(prediction.lng ?? '');
      if (address.isEmpty || latitude == null || longitude == null) return;

      var components = const ParsedAddressComponents();
      final placeId = prediction.placeId?.trim();
      if (placeId != null && placeId.isNotEmpty) {
        components = await fetchAddressComponentsForPlaceId(placeId);
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(
        selectedLocationFromPrediction(
          address: address,
          latitude: latitude,
          longitude: longitude,
          components: components,
        ).toLocationModel(),
      );
    }

    final media = MediaQuery.of(context);
    // ~80% of available height so suggestion overlay still fits under the field.
    final sheetHeight = (media.size.height - media.viewInsets.bottom) * 0.8;

    return SizedBox(
      height: sheetHeight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.none,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                ),
                const SizedBox(height: 12),
                GooglePlaceAutoCompleteTextField(
                  textEditingController: controller,
                  googleAPIKey: EnvConfig.googlePlacesApiKey,
                  focusNode: focusNode,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    color: Color(AppColors.textColor),
                  ),
                  debounceTime: 400,
                  countries: const ['in'],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: onPrediction,
                  itemClick: (prediction) {
                    controller.text = prediction.description ?? '';
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  },
                  inputDecoration: InputDecoration(
                    hintText: 'Search place',
                    hintStyle: const TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                    filled: true,
                    fillColor: const Color(AppColors.backgroundColor),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  boxDecoration: const BoxDecoration(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
