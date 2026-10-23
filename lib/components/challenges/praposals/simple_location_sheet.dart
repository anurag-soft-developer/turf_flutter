import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/config/constants.dart';
import '../../shared/location_autocomplete_field.dart';

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
                Expanded(
                  child: LocationAutocompleteField(
                    controller: controller,
                    autofocus: true,
                    labelText: '',
                    hintText: 'Search place',
                    countries: const ['in'],
                    prefixIcon: Icons.search,
                    onLocationSelected: (location) {
                      Navigator.of(context).pop(location.toLocationModel());
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
