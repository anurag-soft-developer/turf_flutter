import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import '../../turf_booking/model/turf_booking_model.dart';
import '../../turf_booking/turf_booking_service.dart';
import '../../core/config/constants.dart';
import 'booking_reference_card.dart';

class BookingTicketScreen extends StatefulWidget {
  const BookingTicketScreen({super.key});

  @override
  State<BookingTicketScreen> createState() => _BookingTicketScreenState();
}

class _BookingTicketScreenState extends State<BookingTicketScreen> {
  final TurfBookingService _bookingService = TurfBookingService();

  TurfBookingModel? _booking;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    final routeBooking = args['booking'];
    if (routeBooking is TurfBookingModel) {
      setState(() {
        _booking = routeBooking;
        _isLoading = false;
      });
      return;
    }

    final bookingId = _resolveBookingId(args);
    if (bookingId == null || bookingId.isEmpty) {
      setState(() {
        _loadError = 'Booking not found.';
        _isLoading = false;
      });
      return;
    }

    final fetched = await _bookingService.findById(bookingId);
    if (!mounted) return;

    if (fetched == null) {
      setState(() {
        _loadError = 'Could not load booking.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _booking = fetched;
      _isLoading = false;
    });
  }

  String? _resolveBookingId(Map<String, dynamic> args) {
    final fromArg = args['bookingId']?.toString();
    if (fromArg != null && fromArg.isNotEmpty) return fromArg;

    final booking = args['booking'];
    if (booking is TurfBookingModel) {
      return booking.id ?? booking.bookingId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(AppColors.primaryColor),
        appBar: AppBar(
          backgroundColor: const Color(AppColors.primaryColor),
          elevation: 0,
          title: const Text(
            'Ticket',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_loadError != null || _booking == null) {
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
                  _loadError ?? 'Booking not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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

    return _buildTicketContent(_booking!);
  }

  Widget _buildTicketContent(TurfBookingModel booking) {
    return Scaffold(
      backgroundColor: const Color(AppColors.primaryColor),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.primaryColor),
        elevation: 0,
        title: const Text(
          'Ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareTicket(booking),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(AppColors.primaryColor), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: booking.turfHelper.getMainImage() != null
                              ? Image.network(
                                  booking.turfHelper.getMainImage()!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: const Icon(
                                        Icons.grass,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                )
                              : const Icon(
                                  Icons.grass,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Turf Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.turfDisplayName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookingReferenceCard(
                          bookingId: booking.bookingId ?? booking.id,
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: SizedBox(
                              height: 200,
                              width: 200,
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
                        ),
                        const SizedBox(height: 18),
                        _DetailRow(
                          icon: Icons.access_time,
                          iconColor: Colors.blue,
                          label: 'Time',
                          value: booking.bookingTimeDisplay,
                        ),
                        _DetailRow(
                          icon: Icons.calendar_today,
                          iconColor: Colors.orange,
                          label: 'Date',
                          value:
                              booking.startDateTime
                                  ?.toString()
                                  .split(' ')
                                  .first ??
                              'N/A',
                        ),
                        _DetailRow(
                          icon: Icons.people,
                          iconColor: Colors.purple,
                          label: 'Players',
                          value: '${booking.playerCount ?? 0} players',
                        ),
                        _DetailRow(
                          icon: Icons.currency_rupee,
                          iconColor: Colors.green,
                          label: 'Amount',
                          value:
                              '₹${booking.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                        _DetailRow(
                          icon: Icons.info_outline,
                          iconColor: _getStatusColor(booking.status),
                          label: 'Status',
                          value:
                              booking.status?.name.toUpperCase() ?? 'UNKNOWN',
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Show this QR code at the turf for check-in',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TurfBookingStatus? status) {
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

  void _shareTicket(TurfBookingModel booking) {
    final shareText =
        '''
🎫 Turf Booking Ticket

📍 Turf: ${booking.turfDisplayName}
🕒 Time: ${booking.bookingTimeDisplay}
📅 Date: ${booking.startDateTime?.toString().split(' ').first ?? 'N/A'}
👥 Players: ${booking.playerCount ?? 0}
💰 Amount: ₹${booking.totalAmount?.toStringAsFixed(2) ?? '0.00'}
📋 Status: ${booking.status?.name.toUpperCase() ?? 'UNKNOWN'}

🆔 Booking ID: ${booking.id ?? 'N/A'}

Show this at the turf for check-in!
''';

    Share.share(
      shareText,
      subject: 'Turf Booking Ticket #${booking.id?.substring(0, 8) ?? 'N/A'}',
    );
  }

  static void show(TurfBookingModel booking) {
    Get.toNamed(
      AppConstants.routes.bookingTicket,
      arguments: {
        'bookingId': booking.id ?? booking.bookingId,
        'booking': booking,
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(AppColors.textColor),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
