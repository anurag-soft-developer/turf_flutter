import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/media_upload_service.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../model/turf_model.dart';
import '../turf_service.dart';
import '../../core/utils/exception_handler.dart';

class CreateTurfController extends GetxController {
  static CreateTurfController get instance => Get.find();

  final TurfService _turfService = TurfService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController basePriceController = TextEditingController();
  // final TextEditingController weekendSurgeController = TextEditingController();
  final TextEditingController openTimeController = TextEditingController();
  final TextEditingController closeTimeController = TextEditingController();
  // final TextEditingController slotBufferController = TextEditingController();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxList<String> _selectedSportTypes = <String>[].obs;
  final RxList<String> _selectedAmenities = <String>[].obs;
  final RxList<String> _imageUrls = <String>[].obs;
  final RxString _selectedDimensionUnit = 'meters'.obs;
  final Rxn<TurfModel> _editingTurf = Rxn<TurfModel>();
  final RxBool _isEditMode = false.obs;

  /// Storage URLs removed in edit mode; deleted via API only after a successful update.
  final List<String> _pendingRemoteImageDeletes = [];

  // Getters
  RxBool get isLoading => _isLoading;
  RxList<String> get selectedSportTypes => _selectedSportTypes;
  RxList<String> get selectedAmenities => _selectedAmenities;
  RxList<String> get imageUrls => _imageUrls;
  RxString get selectedDimensionUnit => _selectedDimensionUnit;
  Rxn<TurfModel> get editingTurf => _editingTurf;
  RxBool get isEditMode => _isEditMode;

  // Available options
  final List<String> availableSportTypes = [
    'Football',
    'Cricket',
    'Basketball',
    'Tennis',
    'Volleyball',
    'Badminton',
    'Hockey',
    'Baseball',
    'Soccer',
  ];

  final List<String> availableAmenities = [
    'Parking',
    'Restrooms',
    'Changing Rooms',
    'Lighting',
    'Refreshments',
    'Equipment Rental',
    'First Aid',
    'Security',
    'Wi-Fi',
    'Seating Area',
  ];

  final List<String> dimensionUnits = ['meters', 'feet'];

  @override
  void onInit() {
    super.onInit();

    // Check if we're in edit mode (arguments passed from navigation)
    final arguments = Get.arguments;
    if (arguments != null && arguments is TurfModel) {
      _isEditMode.value = true;
      _editingTurf.value = arguments;
      _populateFormFromTurf(arguments);
    } else {
      // Initialize default values for create mode
      openTimeController.text = '06:00';
      closeTimeController.text = '22:00';
    }
  }

  /// Toggle sport type selection
  void toggleSportType(String sportType) {
    if (_selectedSportTypes.contains(sportType)) {
      _selectedSportTypes.remove(sportType);
    } else {
      _selectedSportTypes.add(sportType);
    }
  }

  /// Queue a Spaces object for delete after turf update (edit mode deferred removal).
  void queueDeferredRemoteImageDeletion(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    if (!_pendingRemoteImageDeletes.contains(trimmed)) {
      _pendingRemoteImageDeletes.add(trimmed);
    }
  }

  /// Toggle amenity selection
  void toggleAmenity(String amenity) {
    if (_selectedAmenities.contains(amenity)) {
      _selectedAmenities.remove(amenity);
    } else {
      _selectedAmenities.add(amenity);
    }
  }

  /// Set dimension unit
  void setDimensionUnit(String unit) {
    _selectedDimensionUnit.value = unit;
  }

  /// Pick time
  Future<void> pickTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final String formattedTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  /// Validate form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedSportTypes.isEmpty) {
      ExceptionHandler.showErrorToast('Please select at least one sport type');
      return false;
    }

    if (_imageUrls.isEmpty) {
      ExceptionHandler.showErrorToast('Please add at least one image');
      return false;
    }

    return true;
  }

  /// Submit turf (create or update)
  Future<void> submitTurf() async {
    if (!validateForm()) return;

    try {
      _isLoading.value = true;

      if (_isEditMode.value) {
        await _updateTurf();
      } else {
        await _createTurf();
      }
    } catch (e) {
      final action = _isEditMode.value ? 'update' : 'create';
      debugPrint('Error ${action}ing turf: $e');
      ExceptionHandler.showErrorToast('Failed to $action turf');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Create new turf
  Future<void> _createTurf() async {
    final request = CreateTurfRequest(
      name: _getTrimmedText(nameController),
      description: _getTrimmedText(descriptionController),
      location: _buildLocationModel(),
      dimensions: _buildDimensionsModel(),
      sportType: _selectedSportTypes.toList(),
      pricing: _buildPricingModel(isUpdate: false),
      operatingHours: _buildOperatingHoursModel(),
      images: _getImagesList(),
      amenities: _getAmenitiesList(),
      slotBufferMins: 15, // Default 15 minutes buffer
    );

    final result = await _turfService.createTurf(request);
    _handleTurfOperationResult(result, isUpdate: false);
  }

  /// Update existing turf
  Future<void> _updateTurf() async {
    if (_editingTurf.value?.id == null) return;

    final request = UpdateTurfRequest(
      name: _getTrimmedText(nameController),
      description: _getTrimmedText(descriptionController),
      location: _buildLocationModel(),
      dimensions: _buildDimensionsModel(),
      sportType: _selectedSportTypes.toList(),
      pricing: _buildPricingModel(isUpdate: true),
      operatingHours: _buildOperatingHoursModel(),
      images: _getImagesList(),
      amenities: _getAmenitiesList(),
      slotBufferMins: _editingTurf.value?.slotBufferMins ?? 15,
      isAvailable: _editingTurf.value?.isAvailable ?? false,
    );

    final result = await _turfService.updateTurf(
      _editingTurf.value!.id!,
      request,
    );
    if (result != null) {
      await flushPendingRemoteImageDeletions(_pendingRemoteImageDeletes);
    }
    _handleTurfOperationResult(result, isUpdate: true);
  }

  /// Helper methods for building request objects

  String _getTrimmedText(TextEditingController controller) {
    return controller.text.trim();
  }

  LocationModel _buildLocationModel() {
    return LocationModel(
      address: _getTrimmedText(addressController),
      coordinates: GeoPointModel.fromLngLat(
        longitude: double.tryParse(_getTrimmedText(lngController)) ?? 0,
        latitude: double.tryParse(_getTrimmedText(latController)) ?? 0,
      ),
    );
  }

  DimensionsModel _buildDimensionsModel() {
    return DimensionsModel(
      length: double.tryParse(_getTrimmedText(lengthController)),
      width: double.tryParse(_getTrimmedText(widthController)),
      unit: _selectedDimensionUnit.value,
    );
  }

  PricingModel _buildPricingModel({required bool isUpdate}) {
    return PricingModel(
      basePricePerHour:
          double.tryParse(_getTrimmedText(basePriceController)) ?? 0,
      weekendSurge: isUpdate
          ? (_editingTurf.value?.pricing?.weekendSurge ?? 0.2)
          : 0.2, // Default 20% surge
    );
  }

  OperatingHoursModel _buildOperatingHoursModel() {
    return OperatingHoursModel(
      open: _getTrimmedText(openTimeController),
      close: _getTrimmedText(closeTimeController),
    );
  }

  List<String>? _getImagesList() {
    return _imageUrls.isEmpty ? null : _imageUrls.toList();
  }

  List<String>? _getAmenitiesList() {
    return _selectedAmenities.isEmpty ? null : _selectedAmenities.toList();
  }

  void _handleTurfOperationResult(TurfModel? result, {required bool isUpdate}) {
    if (result != null) {
      final action = isUpdate ? 'updated' : 'created';
      ExceptionHandler.showSuccessToast('Turf $action successfully!');
      Get.back(result: true);
    } else {
      final action = isUpdate ? 'update' : 'create';
      ExceptionHandler.showErrorToast('Failed to $action turf');
    }
  }

  /// Reset form
  void resetForm() {
    // Clear text controllers without triggering form reset which can cause rebuild loops
    nameController.clear();
    descriptionController.clear();
    addressController.clear();
    latController.clear();
    lngController.clear();
    lengthController.clear();
    widthController.clear();
    basePriceController.clear();
    // weekendSurgeController.text = '0.2';
    openTimeController.text = '06:00';
    closeTimeController.text = '22:00';
    // slotBufferController.text = '15';
    _selectedSportTypes.clear();
    _selectedAmenities.clear();
    _imageUrls.clear();
    _pendingRemoteImageDeletes.clear();
    _selectedDimensionUnit.value = 'meters';

    // Reset edit mode
    _isEditMode.value = false;
    _editingTurf.value = null;

    // Show success message
    ExceptionHandler.showSuccessToast('Form reset successfully');
  }

  /// Populate form fields from existing turf data (for edit mode)
  void _populateFormFromTurf(TurfModel turf) {
    _pendingRemoteImageDeletes.clear();

    // Basic info
    nameController.text = turf.name ?? '';
    descriptionController.text = turf.description ?? '';

    // Location
    final loc = turf.location;
    addressController.text = loc?.address ?? '';
    if (loc != null) {
      latController.text = loc.latitude.toString();
      lngController.text = loc.longitude.toString();
    }

    // Dimensions
    if (turf.dimensions?.length != null) {
      lengthController.text = turf.dimensions!.length!.toString();
    }
    if (turf.dimensions?.width != null) {
      widthController.text = turf.dimensions!.width!.toString();
    }
    _selectedDimensionUnit.value = turf.dimensions?.unit ?? 'meters';

    // Pricing
    if (turf.pricing?.basePricePerHour != null) {
      basePriceController.text = turf.pricing!.basePricePerHour.toString();
    }

    // Operating hours
    openTimeController.text = turf.operatingHours?.open ?? '06:00';
    closeTimeController.text = turf.operatingHours?.close ?? '22:00';

    // Sport types
    if (turf.sportType != null) {
      _selectedSportTypes.clear();
      _selectedSportTypes.addAll(turf.sportType!);
    }

    // Amenities
    if (turf.amenities != null) {
      _selectedAmenities.clear();
      _selectedAmenities.addAll(turf.amenities!);
    }

    // Images
    if (turf.images != null) {
      _imageUrls.clear();
      _imageUrls.addAll(turf.images!);
    }
  }

  /// Get form title based on mode
  String get formTitle => _isEditMode.value ? 'Edit Turf' : 'Create New Turf';

  /// Get submit button text based on mode
  String get submitButtonText =>
      _isEditMode.value ? 'Update Turf' : 'Create Turf';

  /// Validators
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateNumber(String? value, String fieldName, {double? min}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Time is required';
    }
    // Basic time format validation (HH:MM)
    if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value.trim())) {
      return 'Please enter a valid time (HH:MM)';
    }
    return null;
  }

  /// Get current location using GPS
  Future<void> getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ExceptionHandler.showErrorToast('Location permissions are required');
        return;
      }

      // Show loading
      ExceptionHandler.showSuccessToast('Getting current location...');

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update controllers
      latController.text = position.latitude.toString();
      lngController.text = position.longitude.toString();

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final addressComponents = [
            placemark.street,
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country,
          ].where((element) => element?.isNotEmpty == true);

          final address = addressComponents.join(', ');
          addressController.text = address;
        }
      } catch (e) {
        // If reverse geocoding fails, just use coordinates
        addressController.text = '${position.latitude}, ${position.longitude}';
      }

      ExceptionHandler.showSuccessToast('Location updated successfully');
    } catch (e) {
      ExceptionHandler.showErrorToast(
        'Failed to get current location: ${e.toString()}',
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    lengthController.dispose();
    widthController.dispose();
    basePriceController.dispose();
    // weekendSurgeController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    // slotBufferController.dispose();
    super.onClose();
  }
}
