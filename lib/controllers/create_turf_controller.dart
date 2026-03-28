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

  // Getters
  RxBool get isLoading => _isLoading;
  RxList<String> get selectedSportTypes => _selectedSportTypes;
  RxList<String> get selectedAmenities => _selectedAmenities;
  RxList<String> get imageUrls => _imageUrls;
  RxString get selectedDimensionUnit => _selectedDimensionUnit;

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
    // Initialize default values
    // weekendSurgeController.text = '0.2'; // 20% default surge
    // slotBufferController.text = '15'; // 15 minutes default buffer
    openTimeController.text = '06:00';
    closeTimeController.text = '22:00';
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

  /// Create turf
  Future<void> createTurf() async {
    if (!validateForm()) return;

    try {
      _isLoading.value = true;

      final request = CreateTurfRequest(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        location: LocationModel(
          address: addressController.text.trim(),
          coordinates: CoordinatesModel(
            lat: double.tryParse(latController.text.trim()),
            lng: double.tryParse(lngController.text.trim()),
          ),
        ),
        images: _imageUrls.toList(),
        amenities: _selectedAmenities.toList(),
        dimensions: DimensionsModel(
          length: double.tryParse(lengthController.text.trim()),
          width: double.tryParse(widthController.text.trim()),
          unit: _selectedDimensionUnit.value,
        ),
        sportType: _selectedSportTypes.toList(),
        pricing: PricingModel(
          basePricePerHour: double.parse(basePriceController.text.trim()),
          weekendSurge: 0,
        ),
        operatingHours: OperatingHoursModel(
          open: openTimeController.text.trim(),
          close: closeTimeController.text.trim(),
        ),
        slotBufferMins: 0,
      );

      final createdTurf = await _turfService.createTurf(request);

      if (createdTurf != null) {
        ExceptionHandler.showSuccessToast('Turf created successfully!');
        Get.back(result: true); // Return to previous screen
      } else {
        ExceptionHandler.showErrorToast('Failed to create turf');
      }
    } catch (e) {
      debugPrint('Error creating turf: $e');
      ExceptionHandler.showErrorToast('Failed to create turf');
    } finally {
      _isLoading.value = false;
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

    // Show success message
    ExceptionHandler.showSuccessToast('Form reset successfully');
  }

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
