import '../../turf/model/turf_model.dart';

/// Instance-based helper for working with dynamic turf fields
///
/// Usage: final helper = TurfFieldInstance(turfField);
/// Then: helper.getId(), helper.getName(), etc.
class TurfFieldInstance {
  final dynamic _turfField;

  TurfFieldInstance(this._turfField);

  /// Gets the turf ID from the field
  String? getId() {
    if (_turfField is String) return _turfField;
    if (_turfField is TurfModel) return _turfField.id;
    return null;
  }

  /// Gets the TurfModel from the field (null if just an ID)
  TurfModel? getModel() {
    if (_turfField is TurfModel) return _turfField;
    return null;
  }

  /// Gets the display name with fallback logic
  String? getName() {
    if (_turfField is TurfModel) {
      return _turfField.displayName;
    }
    return null;
  }

  /// Gets the address
  String? getAddress() {
    if (_turfField is TurfModel) {
      return _turfField.location?.address;
    }
    return null;
  }

  /// Gets the main image
  String? getMainImage() {
    if (_turfField is TurfModel) {
      return _turfField.mainImage;
    }
    return null;
  }

  /// Gets the average rating
  double? getRating() {
    if (_turfField is TurfModel) {
      return _turfField.averageRating;
    }
    return null;
  }

  /// Gets the sport types
  List<String>? getSportTypes() {
    if (_turfField is TurfModel) {
      return _turfField.sportType;
    }
    return null;
  }

  /// Gets the pricing model
  PricingModel? getPricing() {
    if (_turfField is TurfModel) {
      return _turfField.pricing;
    }
    return null;
  }

  /// Gets the operating hours
  OperatingHoursModel? getOperatingHours() {
    if (_turfField is TurfModel) {
      return _turfField.operatingHours;
    }
    return null;
  }

  /// Gets display name with fallback for unknown turfs
  String getDisplayName() {
    final name = getName();
    if (name != null) return name;
    final id = getId();
    return id != null ? 'Turf $id' : 'Unknown Turf';
  }

  /// Checks if the field has a populated turf model
  bool get isPopulated => _turfField is TurfModel;

  /// Checks if the field is just an ID
  bool get isIdOnly => _turfField is String;

  /// Gets availability status
  String getAvailabilityStatus() {
    if (_turfField is TurfModel) {
      return _turfField.availabilityStatus;
    }
    return 'Status Unknown';
  }

  /// Checks if currently open
  bool isCurrentlyOpen() {
    if (_turfField is TurfModel) {
      return _turfField.operatingHours?.isCurrentlyOpen() ?? false;
    }
    return false;
  }
}
