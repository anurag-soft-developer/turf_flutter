import '../../../turf_booking/model/turf_booking_model.dart';

/// Helper for `turfBookingId` JSON: [String] id or populated [TurfBookingModel].
class TurfBookingRefFieldInstance {
  final dynamic _booking;

  TurfBookingRefFieldInstance(this._booking);

  String? getId() {
    if (_booking is String) return _booking;
    if (_booking is TurfBookingModel) return _booking.id;
    return null;
  }

  TurfBookingModel? getModel() {
    if (_booking is TurfBookingModel) return _booking;
    return null;
  }

  String getDisplayName() {
    final m = getModel();
    if (m != null) {
      final id = m.id;
      final status = m.status?.name;
      if (id != null && id.isNotEmpty) {
        final short = id.length > 10 ? id.substring(0, 10) : id;
        if (status != null) {
          return 'Booking $short · $status';
        }
        return 'Booking $short';
      }
      if (status != null) return 'Booking ($status)';
    }
    final id = getId();
    return id != null ? 'Booking $id' : 'No booking';
  }

  bool get isPopulated => _booking is TurfBookingModel;

  bool get isIdOnly => _booking is String;
}
