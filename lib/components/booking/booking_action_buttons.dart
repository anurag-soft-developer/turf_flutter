import 'package:flutter/material.dart';
import '../../core/config/constants.dart';
import '../../turf_booking/model/turf_booking_model.dart';

/// Shared decline/cancel, confirm, and complete actions for a booking.
class BookingActionButtons extends StatelessWidget {
  final TurfBookingModel booking;
  final bool isOwnerView;
  final void Function(String bookingId)? onCancel;
  final void Function(String bookingId)? onConfirm;
  final void Function(String bookingId)? onComplete;

  const BookingActionButtons({
    super.key,
    required this.booking,
    required this.isOwnerView,
    this.onCancel,
    this.onConfirm,
    this.onComplete,
  });

  static bool shouldShow(TurfBookingModel booking) {
    return booking.isPending || booking.isConfirmed;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(booking)) {
      return const SizedBox.shrink();
    }

    final id = booking.id;
    if (id == null) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    if (isOwnerView) {
      if (booking.isPending) {
        children.add(
          _dangerOutlined(
            label: 'Decline',
            onPressed: onCancel != null ? () => onCancel!(id) : null,
          ),
        );
        children.add(
          _successFilled(
            label: 'Confirm',
            onPressed: onConfirm != null ? () => onConfirm!(id) : null,
          ),
        );
      } else if (booking.isConfirmed) {
        children.add(
          _primaryOutlined(
            label: 'Mark complete',
            onPressed: onComplete != null ? () => onComplete!(id) : null,
          ),
        );
      }
    } else {
      if (booking.isPending || booking.isConfirmed) {
        // children.add(
        //   _dangerOutlined(
        //     label: 'Cancel',
        //     onPressed: onCancel != null ? () => onCancel!(id) : null,
        //   ),
        // );
      }
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 10,
        children: children,
      ),
    );
  }
}

Widget _dangerOutlined({
  required String label,
  required VoidCallback? onPressed,
}) {
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFC62828),
      side: const BorderSide(color: Color(0xFFC62828)),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

Widget _successFilled({
  required String label,
  required VoidCallback? onPressed,
}) {
  return FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

Widget _primaryOutlined({
  required String label,
  required VoidCallback? onPressed,
}) {
  const primary = Color(AppColors.primaryColor);
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: const BorderSide(color: primary),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
