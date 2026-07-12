import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/components/bottom_navigation_panel/navigation_controller.dart';
import '../../core/config/sport_types.dart';
import '../../settings/settings_controller.dart';
import '../model/turf_model.dart';

/// UI-only controller for turf list filters/search.
/// Fetching is owned by flutter_query on the screen.
class TurfListController extends GetxController {
  static TurfListController get instance => Get.find();

  final SettingsController settings = Get.find();

  final TextEditingController searchController = TextEditingController();

  final RxBool isSearching = false.obs;
  final RxList<String> selectedSportTypes = <String>[].obs;
  final RxList<String> selectedAmenities = <String>[].obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 5000.0.obs;
  final RxDouble selectedRating = 0.0.obs;
  final RxString sortBy = 'distance:asc'.obs;
  final RxInt filterRevision = 0.obs;

  Timer? _sliderFilterDebounce;
  static const Duration _sliderFilterDebounceDuration = Duration(
    milliseconds: 400,
  );

  final List<SportTypeConfig> availableSportTypes = SportTypes.catalog;

  final List<String> availableAmenities = [
    'Parking',
    'Changing Room',
    'Washrooms',
    'Water Facility',
    'Lighting',
    'First Aid',
    'Equipment Rental',
    'Food Court',
  ];

  @override
  void onInit() {
    super.onInit();
    _applyRouteSportFilter(Get.arguments);
    if (Get.isRegistered<NavigationController>()) {
      final pending =
          Get.find<NavigationController>().takePendingSportFilter();
      if (pending != null) {
        setSportFilter(pending, notify: false);
      }
    }
  }

  @override
  void onClose() {
    _sliderFilterDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void _bumpFilters() {
    filterRevision.value++;
  }

  void notifySearch() {
    isSearching.value = true;
    _bumpFilters();
    // Cleared by screen after query key changes; keep true briefly for UI.
    Future.microtask(() => isSearching.value = false);
  }

  /// Alias used by filter UI widgets.
  void searchTurfs() => notifySearch();

  void _scheduleSliderFilterSearch() {
    _sliderFilterDebounce?.cancel();
    _sliderFilterDebounce = Timer(_sliderFilterDebounceDuration, notifySearch);
  }

  void toggleSportType(String sportType) {
    if (selectedSportTypes.contains(sportType)) {
      selectedSportTypes.remove(sportType);
    } else {
      selectedSportTypes.add(sportType);
    }
    notifySearch();
  }

  void _applyRouteSportFilter(dynamic arguments) {
    if (arguments is! Map<String, dynamic>) return;

    final sportType = arguments['sportType'];
    if (sportType is! String) return;

    selectedSportTypes.clear();
    if (!SportTypes.isAll(sportType)) {
      selectedSportTypes.add(sportType);
    }
  }

  void setSportFilter(String sportType, {bool notify = true}) {
    selectedSportTypes.clear();
    if (!SportTypes.isAll(sportType)) {
      selectedSportTypes.add(sportType);
    }
    if (notify) notifySearch();
  }

  void toggleAmenity(String amenity) {
    if (selectedAmenities.contains(amenity)) {
      selectedAmenities.remove(amenity);
    } else {
      selectedAmenities.add(amenity);
    }
    notifySearch();
  }

  void updatePriceRange(double min, double max) {
    minPrice.value = min;
    maxPrice.value = max;
    _scheduleSliderFilterSearch();
  }

  void updateRating(double rating) {
    selectedRating.value = rating;
    _scheduleSliderFilterSearch();
  }

  void updateSortBy(String value) {
    sortBy.value = value;
    notifySearch();
  }

  void clearFilters() {
    searchController.clear();
    settings.clearCityLocation();
    selectedSportTypes.clear();
    selectedAmenities.clear();
    minPrice.value = 0.0;
    maxPrice.value = 5000.0;
    selectedRating.value = 0.0;
    sortBy.value = 'distance:asc';
    notifySearch();
  }

  void navigateToTurfDetail(TurfModel turf) {
    if (turf.id != null) {
      Get.toNamed('/turf-detail', arguments: {'turfId': turf.id});
    }
  }
}
