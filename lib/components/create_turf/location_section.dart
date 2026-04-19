import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../turf/create/create_turf_controller.dart';
import '../../core/config/env_config.dart';

class LocationSection extends StatefulWidget {
  const LocationSection({super.key});

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  @override
  Widget build(BuildContext context) {
    final controller = CreateTurfController.instance;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: _PlaceAutocompleteField(
        controller: controller.addressController,
        onPlaceSelected: (Prediction prediction) {
          // Auto-populate coordinates
          controller.latController.text = prediction.lat?.toString() ?? '';
          controller.lngController.text = prediction.lng?.toString() ?? '';
          controller.addressController.text = prediction.description ?? '';
        },
      ),
    );
  }
}

// Isolated widget to prevent focus issues
class _PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final Function(Prediction) onPlaceSelected;

  const _PlaceAutocompleteField({
    required this.controller,
    required this.onPlaceSelected,
  });

  @override
  State<_PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<_PlaceAutocompleteField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GooglePlaceAutoCompleteTextField(
      // key: const ValueKey(
      //   'location_autocomplete',
      // ), // Stable key to maintain state
      textEditingController: widget.controller,
      googleAPIKey: EnvConfig.googlePlacesApiKey,
      focusNode: _focusNode,
      textStyle: const TextStyle(color: Colors.black87),
      inputDecoration: const InputDecoration(
        labelText: 'Address *',
        hintText: 'Start typing to search places...',
        // suffixIcon: Icon(Icons.place, color: Colors.grey),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        labelStyle: TextStyle(color: Colors.black87),
        hintStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.transparent,
        // contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      debounceTime: 800, // Slightly longer debounce to reduce API calls
      isLatLngRequired: true,

      // Styled suggestions list
      // containerHorizontalPadding: 16,
      seperatedBuilder: Divider(
        color: Colors.grey.shade300,
        height: 1,
        thickness: 0.5,
      ),
      itemBuilder: (context, index, Prediction prediction) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 235, 235, 235), // Light background
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 3,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.structuredFormatting?.mainText ??
                          prediction.description ??
                          '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors
                            .black87, // Changed to black87 for better contrast
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (prediction.structuredFormatting?.secondaryText !=
                        null) ...[
                      const SizedBox(height: 2),
                      Text(
                        prediction.structuredFormatting!.secondaryText!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 14,
              ),
            ],
          ),
        );
      },

      // Styled container for suggestions
      boxDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),

      getPlaceDetailWithLatLng: (Prediction prediction) {
        widget.onPlaceSelected(prediction);
        // Keep focus on this field instead of losing it
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_focusNode.canRequestFocus) {
            _focusNode.unfocus();
          }
        });
      },

      itemClick: (Prediction prediction) {
        widget.onPlaceSelected(prediction);
        // Properly hide suggestions after selection
        _focusNode.unfocus();
      },
    );
  }
}
