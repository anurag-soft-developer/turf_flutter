import 'package:flutter/material.dart';

import '../../core/models/location_model.dart';
import '../../core/services/places_service.dart';

typedef OnLocationSelected = void Function(SelectedLocation location);

class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final OnLocationSelected onLocationSelected;
  final String labelText;
  final String hintText;
  final List<String> countries;
  final bool citiesOnly;
  final bool autofocus;
  final IconData? prefixIcon;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
    this.labelText = 'Address *',
    this.hintText = 'Start typing to search places...',
    this.countries = const ['in'],
    this.citiesOnly = false,
    this.autofocus = false,
    this.prefixIcon,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final _focusNode = FocusNode();
  final _places = PlacesService.instance;
  int _requestGeneration = 0;

  @override
  void dispose() {
    _requestGeneration++;
    _focusNode.dispose();
    super.dispose();
  }

  Future<Iterable<PlaceSuggestion>> _buildOptions(
    TextEditingValue value,
  ) async {
    final input = value.text.trim();
    if (input.length < 2) {
      _requestGeneration++;
      return const [];
    }

    final generation = ++_requestGeneration;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || generation != _requestGeneration) return const [];

    final suggestions = await _places.autocomplete(
      input: input,
      country: widget.countries.isEmpty ? 'in' : widget.countries.first,
      citiesOnly: widget.citiesOnly,
    );
    if (!mounted || generation != _requestGeneration) return const [];
    return suggestions;
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    final location = await _places.details(suggestion);
    if (!mounted || location == null) return;
    _focusNode.unfocus();
    widget.onLocationSelected(location);
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
      child: RawAutocomplete<PlaceSuggestion>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        displayStringForOption: (option) => option.description,
        optionsBuilder: _buildOptions,
        onSelected: _selectSuggestion,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onFieldSubmitted(),
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              labelText: widget.labelText.isEmpty ? null : widget.labelText,
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(widget.prefixIcon),
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
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final items = options.toList(growable: false);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey.shade300,
                    height: 1,
                    thickness: 0.5,
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = items[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey.shade600,
                      ),
                      title: Text(
                        suggestion.mainText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: suggestion.secondaryText.isEmpty
                          ? null
                          : Text(
                              suggestion.secondaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () => onSelected(suggestion),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
