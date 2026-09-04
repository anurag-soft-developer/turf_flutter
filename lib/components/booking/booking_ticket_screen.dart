import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/utils/exception_handler.dart';
import '../../core/utils/map_launch_util.dart';
import '../../turf_booking/model/turf_booking_model.dart';
import '../../turf_booking/turf_booking_service.dart';
import 'booking_reference_card.dart';
import 'booking_ticket_pdf.dart';

class BookingTicketScreen extends HookWidget {
  const BookingTicketScreen({super.key});

  static void show(TurfBookingModel booking) {
    Get.toNamed(
      AppConstants.routes.bookingTicket,
      arguments: {
        'bookingId': booking.id,
        'booking': booking,
      },
    );
  }

  String? _resolveBookingId(Map<String, dynamic> args) {
    final fromArg = args['bookingId']?.toString();
    if (fromArg != null && fromArg.isNotEmpty) return fromArg;

    final booking = args['booking'];
    if (booking is TurfBookingModel) {
      return booking.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final args = useMemoized(
      () => (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final seedBooking = args['booking'] is TurfBookingModel
        ? args['booking'] as TurfBookingModel
        : null;
    final bookingId = _resolveBookingId(args) ?? seedBooking?.id;

    if (bookingId == null || bookingId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        appBar: AppBar(
          title: const Text('Ticket'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Booking not found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bookingQuery = useQuery<TurfBookingModel, Object>(
      QueryKeys.bookingDetail(bookingId),
      (_) async {
        final fetched = await TurfBookingService().findById(bookingId);
        if (fetched == null) throw Exception('Could not load booking.');
        return fetched;
      },
      retry: noRetry,
      seed: seedBooking,
      enabled: seedBooking == null,
    );

    final booking = bookingQuery.data ?? seedBooking;
    final isLoading =
        bookingQuery.isLoading || (bookingQuery.isFetching && booking == null);

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        appBar: AppBar(
          backgroundColor: const Color(AppColors.surfaceColor),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Ticket',
            style: TextStyle(
              color: Color(AppColors.textColor),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(AppColors.textColor),
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(AppColors.primaryColor),
            ),
          ),
        ),
      );
    }

    if (booking == null) {
      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        appBar: AppBar(
          title: const Text('Ticket'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bookingQuery.isError
                      ? 'Could not load booking.'
                      : 'Booking not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                if (bookingQuery.isError)
                  OutlinedButton(
                    onPressed: () => bookingQuery.refetch(),
                    child: const Text('Retry'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Go back'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return _TicketContent(booking: booking);
  }
}

class _TicketContent extends StatelessWidget {
  const _TicketContent({required this.booking});

  final TurfBookingModel booking;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final dateLabel = _formatDate(booking.startDateTime);
    final turfId = booking.turfId;
    final address = ticketAddress(booking);
    final bookedBy = ticketBookedBy(booking);
    final confirmedOn = _formatDateOrNull(booking.confirmedDateTime);
    final location = booking.turfHelper.getLocation();
    final canOpenMaps = canOpenLocationInMaps(location);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.surfaceColor),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        title: const Text(
          'Ticket',
          style: TextStyle(
            color: Color(AppColors.textColor),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(AppColors.textColor)),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(AppColors.textColor)),
            onPressed: () => _shareTicket(context, booking),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Card(
            color: const Color(AppColors.surfaceColor),
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(AppColors.dividerColor)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TurfHeader(
                    booking: booking,
                    statusColor: statusColor,
                    statusLabel:
                        booking.status?.name.toUpperCase() ?? 'UNKNOWN',
                    onTap: turfId == null || turfId.isEmpty
                        ? null
                        : () => Get.toNamed(
                            AppConstants.routes.turfDetail,
                            arguments: {'turfId': turfId},
                          ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.backgroundColor),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(AppColors.dividerColor),
                      ),
                    ),
                    child: SizedBox(
                      height: 140,
                      width: 140,
                      child: PrettyQrView.data(
                        data: booking.id ?? '',
                        decoration: const PrettyQrDecoration(
                          shape: PrettyQrSmoothSymbol(
                            color: Color(AppColors.primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Show this QR at the turf for check-in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCell(
                    icon: Icons.access_time,
                    iconColor: Colors.blue,
                    label: 'Time',
                    value: booking.bookingTimeDisplay,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  _InfoCell(
                    icon: Icons.calendar_today,
                    iconColor: Colors.orange,
                    label: 'Date',
                    value: dateLabel,
                  ),
                  const SizedBox(height: 8),
                  if (address != null) ...[
                    _InfoCell(
                      icon: Icons.location_on_outlined,
                      iconColor: Colors.red,
                      label: 'Address',
                      value: address,
                      maxLines: 2,
                      onTap: canOpenMaps
                          ? () => openLocationInMaps(location)
                          : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCell(
                          icon: Icons.people,
                          iconColor: Colors.purple,
                          label: 'Players',
                          value: '${booking.playerCount ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoCell(
                          icon: Icons.currency_rupee,
                          iconColor: Colors.green,
                          label: 'Amount',
                          value:
                              '₹${booking.totalAmount?.toStringAsFixed(0) ?? '0'}',
                        ),
                      ),
                    ],
                  ),
                  if (bookedBy != null || confirmedOn != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (bookedBy != null)
                          Expanded(
                            child: _InfoCell(
                              icon: Icons.person_outline,
                              iconColor: Colors.teal,
                              label: 'Booked by',
                              value: bookedBy,
                            ),
                          ),
                        if (bookedBy != null && confirmedOn != null)
                          const SizedBox(width: 8),
                        if (confirmedOn != null)
                          Expanded(
                            child: _InfoCell(
                              icon: Icons.event_available_outlined,
                              iconColor: Colors.indigo,
                              label: 'Booked on',
                              value: confirmedOn,
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  BookingReferenceCard(bookingId: booking.id),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('d MMM y').format(date.toLocal());
  }

  String? _formatDateOrNull(DateTime? date) {
    if (date == null) return null;
    return DateFormat('d MMM y').format(date.toLocal());
  }

  Color _statusColor(TurfBookingStatus? status) {
    switch (status) {
      case TurfBookingStatus.pending:
        return Colors.orange;
      case TurfBookingStatus.confirmed:
        return Colors.green;
      case TurfBookingStatus.cancelled:
        return Colors.red;
      case TurfBookingStatus.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _shareTicket(
    BuildContext context,
    TurfBookingModel booking,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      ),
    );

    try {
      final file = await buildBookingTicketPdf(booking);
      if (context.mounted) Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject:
            'Turf Booking Ticket ${BookingReferenceCard.displayReference(booking.id)}',
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      ExceptionHandler.showErrorToast('Could not share ticket');
    }
  }
}

class _TurfHeader extends StatelessWidget {
  const _TurfHeader({
    required this.booking,
    required this.statusColor,
    required this.statusLabel,
    this.onTap,
  });

  final TurfBookingModel booking;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = booking.turfHelper.getMainImage();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: imageUrl != null
                  ? AppNetworkImage(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: Color(0xFFE8F5E9),
                            child: Icon(
                              Icons.grass,
                              color: Color(AppColors.primaryColor),
                              size: 20,
                            ),
                          ),
                      placeholder: const ColoredBox(
                        color: Color(0xFFE8F5E9),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: Color(0xFFE8F5E9),
                      child: Icon(
                        Icons.grass,
                        color: Color(AppColors.primaryColor),
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              booking.turfDisplayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(AppColors.textSecondaryColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final int maxLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLink = onTap != null;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isLink
                        ? const Color(AppColors.primaryColor)
                        : const Color(AppColors.textColor),
                    height: 1.25,
                    decoration: isLink
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: const Color(AppColors.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          if (isLink)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.open_in_new,
                size: 16,
                color: Color(AppColors.primaryColor),
              ),
            ),
        ],
      ),
    );

    return Material(
      color: const Color(AppColors.backgroundColor),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(AppColors.dividerColor)),
          ),
          child: content,
        ),
      ),
    );
  }
}
