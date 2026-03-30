import 'package:flutter/material.dart';
import '../../turf_booking/model/turf_booking_model.dart';
import '../../core/config/constants.dart';

class BookingCard extends StatelessWidget {
  final TurfBookingModel booking;
  final bool isOwnerView;
  final Function(String)? onCancel;
  final Function(String)? onConfirm;
  final Function(String)? onComplete;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isOwnerView,
    this.onCancel,
    this.onConfirm,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with booking ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${booking.id?.substring(0, 8) ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(AppColors.textColor),
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),

            const SizedBox(height: 12),

            // Turf information
            Row(
              children: [
                const Icon(Icons.grass, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.turfDisplayName,
                    style: const TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Time information
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  booking.bookingTimeDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.startDateTime?.toString().split(' ').first ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Player information (for owner view) or amount (for player view)
            if (isOwnerView) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    booking.bookedByHelper.getDisplayName(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    size: 18,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${booking.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  // const SizedBox(width: 16),
                  // _PaymentStatusChip(paymentStatus: booking.paymentStatus),
                ],
              ),
            ],

            // Action buttons based on status and view type
            if (_shouldShowActions()) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowActions() {
    if (isOwnerView) {
      return booking.isPending || booking.isConfirmed;
    } else {
      return booking.isPending || booking.isConfirmed;
    }
  }

  List<Widget> _buildActionButtons() {
    List<Widget> buttons = [];

    if (isOwnerView) {
      if (booking.isPending) {
        buttons.addAll([
          OutlinedButton(
            onPressed: () => onCancel?.call(booking.id!),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Decline'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => onConfirm?.call(booking.id!),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ]);
      } else if (booking.isConfirmed) {
        buttons.add(
          OutlinedButton(
            onPressed: () => onComplete?.call(booking.id!),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(AppColors.primaryColor),
              side: const BorderSide(color: Color(AppColors.primaryColor)),
            ),
            child: const Text('Mark Complete'),
          ),
        );
      }
    } else {
      if (booking.isPending || booking.isConfirmed) {
        buttons.add(
          OutlinedButton(
            onPressed: () => onCancel?.call(booking.id!),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Cancel'),
          ),
        );
      }
    }

    return buttons;
  }
}

class _StatusChip extends StatelessWidget {
  final TurfBookingStatus? status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case TurfBookingStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: .2);
        textColor = Colors.orange[800]!;
        break;
      case TurfBookingStatus.confirmed:
        backgroundColor = Colors.green.withValues(alpha: .2);
        textColor = Colors.green[800]!;
        break;
      case TurfBookingStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: .2);
        textColor = Colors.red[800]!;
        break;
      case TurfBookingStatus.completed:
        backgroundColor = Colors.blue.withValues(alpha: .2);
        textColor = Colors.blue[800]!;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: .2);
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status?.name.toUpperCase() ?? 'UNKNOWN',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// class _PaymentStatusChip extends StatelessWidget {
//   final PaymentStatus? paymentStatus;

//   const _PaymentStatusChip({required this.paymentStatus});

//   @override
//   Widget build(BuildContext context) {
//     Color backgroundColor;
//     Color textColor;

//     switch (paymentStatus) {
//       case PaymentStatus.pending:
//         backgroundColor = Colors.orange.withOpacity(0.2);
//         textColor = Colors.orange[800]!;
//         break;
//       case PaymentStatus.paid:
//         backgroundColor = Colors.green.withOpacity(0.2);
//         textColor = Colors.green[800]!;
//         break;
//       case PaymentStatus.failed:
//         backgroundColor = Colors.red.withOpacity(0.2);
//         textColor = Colors.red[800]!;
//         break;
//       case PaymentStatus.refunded:
//         backgroundColor = Colors.purple.withOpacity(0.2);
//         textColor = Colors.purple[800]!;
//         break;
//       default:
//         backgroundColor = Colors.grey.withOpacity(0.2);
//         textColor = Colors.grey[800]!;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         paymentStatus?.name.toUpperCase() ?? 'UNKNOWN',
//         style: TextStyle(
//           color: textColor,
//           fontSize: 10,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }
// }
