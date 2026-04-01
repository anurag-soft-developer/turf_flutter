import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import '../../core/config/constants.dart';
import '../../turf_booking/turf_booking_controller.dart';
import '../../core/utils/app_snackbar.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;
  bool _isValidating = false;
  final bookingController = TurfBookingController.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Booking QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Stack(
        children: [
          // QR Scanner
          if (_isScanning)
            AiBarcodeScanner(
              onDetect: (BarcodeCapture capture) {
                if (!_isScanning || _isValidating) return;

                final String? scannedData = capture.barcodes.first.rawValue;
                if (scannedData != null && scannedData.isNotEmpty) {
                  _handleScanResult(scannedData);
                }
              },
            ),

          // Overlay with instructions
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: .7),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Top instructions
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Position the QR code within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The booking details will appear automatically',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isValidating)
            Container(
              color: Colors.black.withValues(alpha: .7),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(AppColors.primaryColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Validating booking...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleScanResult(String scannedData) async {
    if (_isValidating) return;

    setState(() {
      _isScanning = false;
      _isValidating = true;
    });

    try {
      // Validate the scanned booking ID
      final booking = await bookingController.validateBookingForCheckIn(
        scannedData,
      );

      if (booking != null) {
        // Show check-in dialog
        _showCheckInDialog(booking);
      } else {
        AppSnackbar.error(
          title: 'Invalid QR Code',
          message: 'This booking was not found or is not valid for check-in',
        );
        _resetScanner();
      }
    } catch (e) {
      AppSnackbar.error(
        title: 'Scan Error',
        message: 'Failed to validate booking. Please try again.',
      );
      _resetScanner();
    }
  }

  void _showCheckInDialog(dynamic booking) {
    Get.dialog(
      AlertDialog(
        title: const Text('Check-in Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking #${booking.id?.substring(0, 8) ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Turf: ${booking.turfDisplayName}'),
            Text('Time: ${booking.bookingTimeDisplay}'),
            Text('Players: ${booking.playerCount ?? 0}'),
            Text('Customer: ${booking.bookedByHelper.getDisplayName()}'),
            const SizedBox(height: 16),
            const Text(
              'Mark this booking as checked-in?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                    _resetScanner();
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _performCheckIn(booking.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Check-in'),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _performCheckIn(String? bookingId) async {
    if (bookingId == null) return;

    Get.back(); // Close dialog

    try {
      final success = await bookingController.checkInBooking(bookingId);
      if (success) {
        AppSnackbar.success(
          title: 'Check-in Successful',
          message: 'Customer has been checked in successfully',
        );
        Get.back(); // Return to previous screen
      } else {
        AppSnackbar.error(
          title: 'Check-in Failed',
          message: 'Failed to check in. Please try again.',
        );
        _resetScanner();
      }
    } catch (e) {
      AppSnackbar.error(
        title: 'Check-in Error',
        message: 'An error occurred during check-in',
      );
      _resetScanner();
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isValidating = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
