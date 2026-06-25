import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../core/config/sport_types.dart';
import '../model/turf_model.dart';
// import '../models/common/paginated_response.dart';
import '../turf_service.dart';
import '../../settings/settings_controller.dart';

class TurfListController extends GetxController {
  static TurfListController get instance => Get.find();

  final TurfService _turfService = TurfService();
  final SettingsController settings = Get.find();

  // Form controllers
  final TextEditingController searchController = TextEditingController();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxBool _isSearching = false.obs;
  final RxList<TurfModel> _turfs = <TurfModel>[].obs;
  final RxList<TurfModel> _featuredTurfs = <TurfModel>[].obs;
  final RxBool _isFeaturedLoading = false.obs;
  final RxList<String> _selectedSportTypes = <String>[].obs;
  final RxList<String> _selectedAmenities = <String>[].obs;
  final RxDouble _minPrice = 0.0.obs;
  final RxDouble _maxPrice = 5000.0.obs;
  final RxDouble _selectedRating = 0.0.obs;
  // final RxBool _isAvailableOnly = true.obs;
  final RxString _sortBy = 'distance:asc'.obs;

  // Pagination
  int _loadedPage = 0;
  final RxBool _hasMoreData = true.obs;
  final RxInt _totalItems = 0.obs;
  final int _limitPerPage = 10;

  Timer? _sliderFilterDebounce;
  static const Duration _sliderFilterDebounceDuration = Duration(
    milliseconds: 400,
  );

  // Getters - Return observables for reactivity
  RxBool get isLoading => _isLoading;
  RxBool get isLoadingMore => _isLoadingMore;
  RxBool get isSearching => _isSearching;
  RxList<TurfModel> get turfs => _turfs;
  RxList<TurfModel> get featuredTurfs => _featuredTurfs;
  RxBool get isFeaturedLoading => _isFeaturedLoading;
  RxList<String> get selectedSportTypes => _selectedSportTypes;
  RxList<String> get selectedAmenities => _selectedAmenities;
  RxDouble get minPrice => _minPrice;
  RxDouble get maxPrice => _maxPrice;
  RxDouble get selectedRating => _selectedRating;
  // RxBool get isAvailableOnly => _isAvailableOnly;
  RxString get sortBy => _sortBy;
  RxBool get hasMoreData => _hasMoreData;
  RxInt get totalItems => _totalItems;

  // Filter options
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

    loadFeaturedTurfs();
    loadTurfs(isRefresh: true);
  }

  @override
  void onClose() {
    _sliderFilterDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  // Load featured turfs for home section
  Future<void> loadFeaturedTurfs() async {
    _isFeaturedLoading.value = true;
    try {
      final turfs = await _turfService.getFeaturedTurfs(limit: 5);
      if (turfs != null) {
        _featuredTurfs.value = turfs;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load featured turfs');
    } finally {
      _isFeaturedLoading.value = false;
    }
  }

  // Load turfs with current filters
  Future<void> loadTurfs({bool isRefresh = false}) async {
    if (isRefresh) {
      if (_isLoading.value) return;
      _loadedPage = 0;
      _hasMoreData.value = true;
      _turfs.clear();
      _isLoading.value = true;
    } else {
      if (_isLoadingMore.value || !_hasMoreData.value || _isLoading.value) {
        return;
      }
      _isLoadingMore.value = true;
    }

    final pageToLoad = isRefresh ? 1 : _loadedPage + 1;

    try {
      final response = await _turfService.searchTurfs(
        globalSearchText: searchController.text.trim().isNotEmpty
            ? searchController.text.trim()
            : null,
        sportTypes: _selectedSportTypes.isNotEmpty ? _selectedSportTypes : null,
        amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
        location: settings.selectedCityLocation.value,
        minPrice: _minPrice.value > 0 ? _minPrice.value : null,
        maxPrice: _maxPrice.value < 5000 ? _maxPrice.value : null,
        // isAvailable: _isAvailableOnly.value,
        minRating: _selectedRating.value > 0 ? _selectedRating.value : null,
        page: pageToLoad,
        limit: _limitPerPage,
        sort: _sortBy.value,
      );

      if (response != null) {
        if (isRefresh) {
          _turfs.value = response.data;
        } else {
          _turfs.addAll(response.data);
        }

        _loadedPage = response.page;
        _totalItems.value = response.totalDocuments;
        _hasMoreData.value = response.hasNextPage;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load turfs');
    } finally {
      _isLoading.value = false;
      _isLoadingMore.value = false;
    }
  }

  // Search turfs
  Future<void> searchTurfs() async {
    _sliderFilterDebounce?.cancel();
    _isSearching.value = true;
    await loadTurfs(isRefresh: true);
    _isSearching.value = false;
  }

  void _scheduleSliderFilterSearch() {
    _sliderFilterDebounce?.cancel();
    _sliderFilterDebounce = Timer(_sliderFilterDebounceDuration, () {
      searchTurfs();
    });
  }

  // Load more turfs for pagination
  Future<void> loadMoreTurfs() => loadTurfs();

  // Refresh turfs
  Future<void> refreshTurfs() async {
    await loadTurfs(isRefresh: true);
  }

  // Filter methods
  void toggleSportType(String sportType) {
    if (_selectedSportTypes.contains(sportType)) {
      _selectedSportTypes.remove(sportType);
    } else {
      _selectedSportTypes.add(sportType);
    }
    searchTurfs();
  }

  void _applyRouteSportFilter(dynamic arguments) {
    if (arguments is! Map<String, dynamic>) return;

    final sportType = arguments['sportType'];
    if (sportType is! String) return;

    _selectedSportTypes.clear();
    if (!SportTypes.isAll(sportType)) {
      _selectedSportTypes.add(sportType);
    }
  }

  // Set sport filter directly (used when navigating from dashboard)
  void setSportFilter(String sportType) {
    _selectedSportTypes.clear();
    if (!SportTypes.isAll(sportType)) {
      _selectedSportTypes.add(sportType);
    }
    searchTurfs();
  }

  void toggleAmenity(String amenity) {
    if (_selectedAmenities.contains(amenity)) {
      _selectedAmenities.remove(amenity);
    } else {
      _selectedAmenities.add(amenity);
    }
    searchTurfs();
  }

  void updatePriceRange(double min, double max) {
    _minPrice.value = min;
    _maxPrice.value = max;
    _scheduleSliderFilterSearch();
  }

  void updateRating(double rating) {
    _selectedRating.value = rating;
    _scheduleSliderFilterSearch();
  }

  void updateSortBy(String sortBy) {
    _sortBy.value = sortBy;
    searchTurfs();
  }

  // Clear all filters
  void clearFilters() {
    searchController.clear();
    settings.clearCityLocation();
    _selectedSportTypes.clear();
    _selectedAmenities.clear();
    _minPrice.value = 0.0;
    _maxPrice.value = 5000.0;
    _selectedRating.value = 0.0;
    _sortBy.value = 'distance:asc';
    searchTurfs();
  }

  // Navigate to turf detail
  void navigateToTurfDetail(TurfModel turf) {
    if (turf.id != null) {
      Get.toNamed('/turf-detail', arguments: {'turfId': turf.id});
    }
  }
}
