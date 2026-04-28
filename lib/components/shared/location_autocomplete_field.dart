import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:google_places_flutter/model/prediction.dart';

import '../../core/config/env_config.dart';

typedef OnLocationSelected =
    void Function(String address, double? latitude, double? longitude);

class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final OnLocationSelected onLocationSelected;
  final String labelText;
  final String hintText;
  final List<String> countries;
  final PlaceType? placeType;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
    this.labelText = 'Address *',
    this.hintText = 'Start typing to search places...',
    this.countries = const ['in'],
    this.placeType,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
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

  void _onPredictionSelected(Prediction prediction) {
    final address = prediction.description ?? '';
    final latitude = double.tryParse(prediction.lat ?? '');
    final longitude = double.tryParse(prediction.lng ?? '');
    widget.onLocationSelected(address, latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
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
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: widget.controller,
        googleAPIKey: EnvConfig.googlePlacesApiKey,
        focusNode: _focusNode,
        textStyle: const TextStyle(color: Colors.black87),
        inputDecoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.transparent,
        ),
        debounceTime: 800,
        isLatLngRequired: true,
        countries: widget.countries,
        placeType: widget.placeType,
        seperatedBuilder: Divider(
          color: Colors.grey.shade300,
          height: 1,
          thickness: 0.5,
        ),
        itemBuilder: (context, index, prediction) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 235, 235, 235),
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
                          color: Colors.black87,
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
        getPlaceDetailWithLatLng: (prediction) {
          _onPredictionSelected(prediction);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_focusNode.canRequestFocus) {
              _focusNode.unfocus();
            }
          });
        },
        itemClick: (prediction) {
          _focusNode.unfocus();
        },
      ),
    );
  }
}
