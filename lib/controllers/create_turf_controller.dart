import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/turf_model.dart';
import '../services/turf_service.dart';
import '../utils/exception_handler.dart';

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

  /// Toggle amenity selection
  void toggleAmenity(String amenity) {
    if (_selectedAmenities.contains(amenity)) {
      _selectedAmenities.remove(amenity);
    } else {
      _selectedAmenities.add(amenity);
    }
  }

  /// Add image URL
  void addImageUrl(String url) {
    if (url.isNotEmpty && !_imageUrls.contains(url)) {
      _imageUrls.add(url);
    }
  }

  /// Remove image URL
  void removeImageUrl(String url) {
    _imageUrls.remove(url);
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } on PlatformException catch (e) {
      String errorMessage = 'Failed to pick image from gallery';

      if (e.code == 'channel-error') {
        errorMessage =
            'Camera/Gallery service unavailable. Please restart the app and try again.';
      } else if (e.code == 'photo_access_denied' ||
          e.message?.contains('Permission denied') == true) {
        errorMessage =
            'Gallery access denied. Please enable photo library permissions in your device settings.';
      } else if (e.code == 'photo_access_restricted') {
        errorMessage = 'Photo library access is restricted on this device.';
      }

      debugPrint('Gallery picker error: ${e.code} - ${e.message}');
      ExceptionHandler.showErrorToast(errorMessage);
    } on Exception catch (e) {
      debugPrint('Gallery picker error: $e');
      ExceptionHandler.showErrorToast('Failed to pick image from gallery');
    }
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } on PlatformException catch (e) {
      String errorMessage = 'Failed to take photo';

      if (e.code == 'channel-error') {
        errorMessage =
            'Camera service unavailable. Please restart the app and try again.';
      } else if (e.code == 'camera_access_denied' ||
          e.message?.contains('Permission denied') == true) {
        errorMessage =
            'Camera access denied. Please enable camera permissions in your device settings.';
      } else if (e.code == 'camera_access_restricted') {
        errorMessage = 'Camera access is restricted on this device.';
      } else if (e.code == 'camera_no_available') {
        errorMessage = 'No camera available on this device.';
      }

      debugPrint('Camera picker error: ${e.code} - ${e.message}');
      ExceptionHandler.showErrorToast(errorMessage);
    } on Exception catch (e) {
      debugPrint('Camera picker error: $e');
      ExceptionHandler.showErrorToast('Failed to take photo');
    }
  }

  /// Upload image to service (placeholder - replace with your upload logic)
  Future<void> _uploadImage(File imageFile) async {
    try {
      _isLoading.value = true;

      // TODO: Replace this with your actual image upload service
      // For now, we'll simulate an upload and use a placeholder URL
      await Future.delayed(const Duration(seconds: 1));

      // Generate a placeholder URL (replace with actual uploaded URL)
      final String uploadedUrl =
          'https://fastly.picsum.photos/id/363/200/300.jpg?hmac=LvonEMeE2QnwxULuBZW5xHtdjkz844GnAPpEhDwGvMY';

      _imageUrls.add(uploadedUrl);

      ExceptionHandler.showSuccessToast('Image uploaded successfully');
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to upload image');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Show image picker options
  void showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Image URL'),
              subtitle: const Text('Add from web URL'),
              onTap: () {
                Get.back();
                _showUrlDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show URL input dialog
  void _showUrlDialog() {
    final TextEditingController urlController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Image URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'Paste image URL here',
            prefixIcon: Icon(Icons.link),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              addImageUrl(value.trim());
              Get.back();
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                addImageUrl(url);
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
    _handleTurfOperationResult(result, isUpdate: true);
  }

  /// Helper methods for building request objects

  String _getTrimmedText(TextEditingController controller) {
    return controller.text.trim();
  }

  LocationModel _buildLocationModel() {
    return LocationModel(
      address: _getTrimmedText(addressController),
      coordinates: CoordinatesModel(
        lat: double.tryParse(_getTrimmedText(latController)),
        lng: double.tryParse(_getTrimmedText(lngController)),
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
    _selectedDimensionUnit.value = 'meters';

    // Reset edit mode
    _isEditMode.value = false;
    _editingTurf.value = null;

    // Show success message
    ExceptionHandler.showSuccessToast('Form reset successfully');
  }

  /// Populate form fields from existing turf data (for edit mode)
  void _populateFormFromTurf(TurfModel turf) {
    // Basic info
    nameController.text = turf.name ?? '';
    descriptionController.text = turf.description ?? '';

    // Location
    addressController.text = turf.location?.address ?? '';
    if (turf.location?.coordinates?.lat != null) {
      latController.text = turf.location!.coordinates!.lat!.toString();
    }
    if (turf.location?.coordinates?.lng != null) {
      lngController.text = turf.location!.coordinates!.lng!.toString();
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
