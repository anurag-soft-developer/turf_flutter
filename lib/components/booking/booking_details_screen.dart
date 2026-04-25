import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../turf_booking/model/turf_booking_model.dart';
import '../../core/config/constants.dart';
import '../../core/utils/date_util.dart';
import '../../core/models/user_field_instance.dart';
import 'booking_action_buttons.dart';
import 'booking_action_dialogs.dart';
import 'booking_reference_card.dart';

/// Full-screen booking details for turf owners (proprietor mode).
class BookingDetailsScreen extends StatelessWidget {
  final TurfBookingModel? booking;

  const BookingDetailsScreen({super.key, this.booking});

  static void open(TurfBookingModel booking) {
    Get.toNamed(
      AppConstants.routes.bookingDetails,
      arguments: {'booking': booking},
    );
  }

  static const _primary = Color(AppColors.primaryColor);

  TurfBookingModel _resolveBooking() {
    if (booking != null) return booking!;

    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final routeBooking = args['booking'];
      if (routeBooking is TurfBookingModel) {
        return routeBooking;
      }
    }

    throw Exception('Booking details requires a TurfBookingModel argument.');
  }

  @override
  Widget build(BuildContext context) {
    final booking = _resolveBooking();
    final h = booking.bookedByHelper;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Booking details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingReferenceCard(
              bookingId: booking.id,
              margin: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            _CustomerCard(helper: h),
            const SizedBox(height: 16),

            _ModernSection(
              title: 'Turf & schedule',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.grass_rounded,
                    label: 'Turf',
                    value: booking.turfDisplayName,
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: booking.startDateTime != null
                        ? formatDateOnly(booking.startDateTime!, localeName)
                        : '—',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: booking.bookingTimeDisplay,
                  ),
                  if (booking.timeSlots != null &&
                      booking.timeSlots!.length > 1) ...[
                    const Divider(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Time slots',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...booking.timeSlots!.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.key + 1}.',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value.timeDisplay,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(AppColors.textColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ModernSection(
              title: 'Booking',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.people_rounded,
                    label: 'Players',
                    value: '${booking.playerCount ?? 0}',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.payments_rounded,
                    label: 'Amount',
                    value:
                        '₹${booking.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.flag_rounded,
                    label: 'Status',
                    value: booking.statusDisplay,
                    valueColor: _statusColor(booking.status),
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.credit_card_rounded,
                    label: 'Payment',
                    value: booking.paymentStatusDisplay,
                  ),
                  if (booking.paymentId != null &&
                      booking.paymentId!.isNotEmpty) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.receipt_long_rounded,
                      label: 'Payment ID',
                      value: booking.paymentId!,
                      denseValue: true,
                    ),
                  ],
                ],
              ),
            ),
            if (booking.notes != null && booking.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _ModernSection(
                title: 'Notes',
                child: Text(
                  booking.notes!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                    color: const Color(AppColors.textColor),
                  ),
                ),
              ),
            ],
            if (booking.isCancelled &&
                booking.cancelReason != null &&
                booking.cancelReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _ModernSection(
                title: 'Cancellation',
                child: Text(
                  booking.cancelReason!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                    color: const Color(AppColors.textColor),
                  ),
                ),
              ),
            ],
            if (BookingActionButtons.shouldShow(booking)) ...[
              const SizedBox(height: 16),
              _ModernSection(
                title: 'Actions',
                child: Align(
                  alignment: Alignment.centerRight,
                  child: BookingActionButtons(
                    booking: booking,
                    isOwnerView: true,
                    onCancel: BookingActionDialogs.showCancelBooking,
                    onConfirm: BookingActionDialogs.showConfirmBooking,
                    onComplete: BookingActionDialogs.showCompleteBooking,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _ModernSection(
              title: 'Timeline',
              child: Column(
                children: [
                  if (booking.createdAt != null)
                    _InfoRow(
                      icon: Icons.event_available_rounded,
                      label: 'Booked at',
                      value: formatDateTime(booking.createdAt!, localeName),
                    ),
                  if (booking.confirmedAt != null) ...[
                    if (booking.createdAt != null) const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.check_circle_rounded,
                      label: 'Confirmed at',
                      value: formatDateTime(booking.confirmedAt!, localeName),
                    ),
                  ],
                  if (booking.cancelledAt != null) ...[
                    if (booking.createdAt != null ||
                        booking.confirmedAt != null)
                      const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.cancel_rounded,
                      label: 'Cancelled at',
                      value: formatDateTime(booking.cancelledAt!, localeName),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color? _statusColor(TurfBookingStatus? status) {
    switch (status) {
      case TurfBookingStatus.pending:
        return Colors.orange.shade800;
      case TurfBookingStatus.confirmed:
        return Colors.green.shade800;
      case TurfBookingStatus.cancelled:
        return Colors.red.shade800;
      case TurfBookingStatus.completed:
        return Colors.blue.shade800;
      default:
        return null;
    }
  }
}

class _CustomerCard extends StatelessWidget {
  final UserFieldInstance helper;

  const _CustomerCard({required this.helper});

  @override
  Widget build(BuildContext context) {
    final name = helper.getDisplayName();
    final email = helper.getEmail();
    final avatarUrl = helper.getAvatar();

    final initials = _initials(name);

    return _ModernSection(
      title: 'Customer',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(url: avatarUrl, initials: initials),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(AppColors.textColor),
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return '?';
    if (list.length == 1) {
      return list[0].length >= 2
          ? list[0].substring(0, 2).toUpperCase()
          : list[0].toUpperCase();
    }
    return (list[0][0] + list[1][0]).toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String initials;

  const _Avatar({required this.url, required this.initials});

  @override
  Widget build(BuildContext context) {
    const size = 55.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(AppColors.primaryColor).withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(AppColors.primaryColor),
        ),
      ),
    );
  }
}

class _ModernSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ModernSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: const Color(AppColors.primaryColor).withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool denseValue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.denseValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(AppColors.primaryColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: denseValue ? 13 : 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(AppColors.textColor),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
