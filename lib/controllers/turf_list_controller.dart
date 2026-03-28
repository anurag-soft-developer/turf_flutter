import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/turf_model.dart';
// import '../models/common/paginated_response.dart';
import '../services/turf_service.dart';

class TurfListController extends GetxController {
  static TurfListController get instance => Get.find();

  final TurfService _turfService = TurfService();

  // Form controllers
  final TextEditingController searchController = TextEditingController();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxBool _isSearching = false.obs;
  final RxList<TurfModel> _turfs = <TurfModel>[].obs;
  final RxList<TurfModel> _featuredTurfs = <TurfModel>[].obs;
  final RxList<String> _selectedSportTypes = <String>[].obs;
  final RxList<String> _selectedAmenities = <String>[].obs;
  final RxDouble _minPrice = 0.0.obs;
  final RxDouble _maxPrice = 5000.0.obs;
  final RxDouble _selectedRating = 0.0.obs;
  // final RxBool _isAvailableOnly = true.obs;
  final RxString _sortBy = 'averageRating'.obs;

  // Pagination
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMoreData = true.obs;
  final RxInt _totalItems = 0.obs;
  final int _limitPerPage = 10;

  // Getters - Return observables for reactivity
  RxBool get isLoading => _isLoading;
  RxBool get isSearching => _isSearching;
  RxList<TurfModel> get turfs => _turfs;
  RxList<TurfModel> get featuredTurfs => _featuredTurfs;
  RxList<String> get selectedSportTypes => _selectedSportTypes;
  RxList<String> get selectedAmenities => _selectedAmenities;
  RxDouble get minPrice => _minPrice;
  RxDouble get maxPrice => _maxPrice;
  RxDouble get selectedRating => _selectedRating;
  // RxBool get isAvailableOnly => _isAvailableOnly;
  RxString get sortBy => _sortBy;
  RxInt get currentPage => _currentPage;
  RxBool get hasMoreData => _hasMoreData;
  RxInt get totalItems => _totalItems;

  // Filter options
  final List<String> availableSportTypes = [
    'Football',
    'Cricket',
    'Basketball',
    'Badminton',
    'Tennis',
    'Volleyball',
    'Hockey',
  ];

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

  final List<String> sortOptions = [
    'averageRating',
    'name',
    'pricing',
    'createdAt',
  ];

  @override
  void onInit() {
    super.onInit();

    // Handle navigation arguments for pre-selected sport
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      final String? sportType = arguments['sportType'];
      if (sportType != null && sportType != 'All') {
        _selectedSportTypes.add(sportType);
      }
    }

    loadFeaturedTurfs();
    loadTurfs();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load featured turfs for home section
  Future<void> loadFeaturedTurfs() async {
    try {
      final turfs = await _turfService.getFeaturedTurfs(limit: 5);
      if (turfs != null) {
        _featuredTurfs.value = turfs;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load featured turfs');
    }
  }

  // Load turfs with current filters
  Future<void> loadTurfs({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage.value = 1;
      _hasMoreData.value = true;
      _turfs.clear();
    }

    if (!_hasMoreData.value) return;

    _isLoading.value = true;

    try {
      final response = await _turfService.searchTurfs(
        globalSearchText: searchController.text.trim().isNotEmpty
            ? searchController.text.trim()
            : null,
        sportTypes: _selectedSportTypes.isNotEmpty ? _selectedSportTypes : null,
        amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
        minPrice: _minPrice.value > 0 ? _minPrice.value : null,
        maxPrice: _maxPrice.value < 5000 ? _maxPrice.value : null,
        // isAvailable: _isAvailableOnly.value,
        minRating: _selectedRating.value > 0 ? _selectedRating.value : null,
        page: _currentPage.value,
        limit: _limitPerPage,
        sort: _sortBy.value,
      );

      if (response != null) {
        if (isRefresh) {
          _turfs.value = response.data;
          _totalItems.value = response.totalDocuments;
        } else {
          _turfs.addAll(response.data);
        }

        _hasMoreData.value = response.hasNextPage;
        if (!isRefresh && response.hasNextPage) {
          _currentPage.value++;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load turfs');
    } finally {
      _isLoading.value = false;
    }
  }

  // Search turfs
  Future<void> searchTurfs() async {
    _isSearching.value = true;
    await loadTurfs(isRefresh: true);
    _isSearching.value = false;
  }

  // Load more turfs for pagination
  Future<void> loadMoreTurfs() async {
    if (!_isLoading.value && _hasMoreData.value) {
      await loadTurfs();
    }
  }

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

  // Set sport filter directly (used when navigating from dashboard)
  void setSportFilter(String sportType) {
    _selectedSportTypes.clear();
    if (sportType != 'All') {
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
    searchTurfs();
  }

  void updateRating(double rating) {
    _selectedRating.value = rating;
    searchTurfs();
  }

  // void toggleAvailabilityFilter() {
  //   _isAvailableOnly.value = !_isAvailableOnly.value;
  //   searchTurfs();
  // }

  void updateSortBy(String sortBy) {
    _sortBy.value = sortBy;
    searchTurfs();
  }

  // Clear all filters
  void clearFilters() {
    searchController.clear();
    _selectedSportTypes.clear();
    _selectedAmenities.clear();
    _minPrice.value = 0.0;
    _maxPrice.value = 5000.0;
    _selectedRating.value = 0.0;
    // _isAvailableOnly.value = true;
    _sortBy.value = 'averageRating';
    searchTurfs();
  }

  // Navigate to turf detail
  void navigateToTurfDetail(TurfModel turf) {
    if (turf.id != null) {
      Get.toNamed('/turf-detail', arguments: {'turfId': turf.id});
    }
  }
}
