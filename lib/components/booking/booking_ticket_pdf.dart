import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/map_launch_util.dart';
import '../../turf_booking/model/turf_booking_model.dart';
import 'booking_reference_card.dart';

const _pageBg = PdfColor.fromInt(0xFFF9FAFB);
const _cardBg = PdfColors.white;
const _cardBorder = PdfColor.fromInt(0xFFD7D8DA);
const _text = PdfColor.fromInt(0xFF111827);
const _textMuted = PdfColor.fromInt(0xFF6B7280);
const _primary = PdfColor.fromInt(0xFF38761D);
const _qrColor = PdfColors.black;

String? ticketAddress(TurfBookingModel booking) {
  final loc = booking.turfHelper.getLocation();
  if (loc == null) return null;
  final address = loc.address.trim();
  final parts = <String>[];
  if (address.isNotEmpty) parts.add(address);
  final city = loc.city?.trim();
  if (city != null &&
      city.isNotEmpty &&
      !address.toLowerCase().contains(city.toLowerCase())) {
    parts.add(city);
  }
  final state = loc.state?.trim();
  if (state != null &&
      state.isNotEmpty &&
      !address.toLowerCase().contains(state.toLowerCase())) {
    parts.add(state);
  }
  if (parts.isEmpty) return null;
  return parts.join(', ');
}

String? ticketBookedBy(TurfBookingModel booking) {
  final name = booking.bookedByHelper.getName();
  if (name == null || name.trim().isEmpty) return null;
  return name.trim();
}

Future<File> buildBookingTicketPdf(TurfBookingModel booking) async {
  final doc = pw.Document();
  final id = booking.id ?? '';
  final reference = BookingReferenceCard.displayReference(booking.id);
  final dateLabel = booking.startDateTime == null
      ? 'N/A'
      : DateFormat('d MMM y').format(booking.startDateTime!.toLocal());
  final status = booking.status?.name.toUpperCase() ?? 'UNKNOWN';
  final amount = 'Rs. ${booking.totalAmount?.toStringAsFixed(0) ?? '0'}';
  final address = ticketAddress(booking);
  final bookedBy = ticketBookedBy(booking);
  final confirmedOn = booking.confirmedDateTime == null
      ? null
      : DateFormat('d MMM y').format(booking.confirmedDateTime!.toLocal());
  final mapsUrl = buildLocationMapsHttpsUri(
    booking.turfHelper.getLocation(),
  )?.toString();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(20),
      build: (context) {
        return pw.Container(
          color: _pageBg,
          padding: const pw.EdgeInsets.all(12),
          child: pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: pw.BoxDecoration(
              color: _cardBg,
              border: pw.Border.all(color: _cardBorder),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _linkedText(
                        booking.turfDisplayName,
                        mapsUrl,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: mapsUrl == null ? _text : _primary,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _statusChipBg(booking.status),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        status,
                        style: pw.TextStyle(
                          color: _statusChipFg(booking.status),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: _cardBorder),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: id.isEmpty ? 'N/A' : id,
                      width: 140,
                      height: 140,
                      color: _qrColor,
                      drawText: false,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Show this QR at the turf for check-in',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 11, color: _textMuted),
                ),
                pw.SizedBox(height: 12),
                _infoCell('Time', booking.bookingTimeDisplay),
                pw.SizedBox(height: 8),
                _infoCell('Date', dateLabel),
                if (address != null) ...[
                  pw.SizedBox(height: 8),
                  _infoCell('Address', address, url: mapsUrl),
                ],
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _infoCell(
                        'Players',
                        '${booking.playerCount ?? 0}',
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: _infoCell('Amount', amount)),
                  ],
                ),
                if (bookedBy != null || confirmedOn != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      if (bookedBy != null)
                        pw.Expanded(child: _infoCell('Booked by', bookedBy)),
                      if (bookedBy != null && confirmedOn != null)
                        pw.SizedBox(width: 8),
                      if (confirmedOn != null)
                        pw.Expanded(child: _infoCell('Booked on', confirmedOn)),
                    ],
                  ),
                ],
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: _cardBorder, width: 0.6),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Ref',
                        style: pw.TextStyle(fontSize: 9, color: _textMuted),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          reference,
                          maxLines: 1,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: _text,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  final safeId = id.isEmpty ? 'unknown' : id;
  final file = File('${Directory.systemTemp.path}/turf_ticket_$safeId.pdf');
  await file.writeAsBytes(await doc.save());
  return file;
}

pw.Widget _linkedText(String text, String? url, {required pw.TextStyle style}) {
  final child = pw.Text(
    text,
    maxLines: 2,
    style: url == null
        ? style
        : style.copyWith(decoration: pw.TextDecoration.underline),
  );
  if (url == null) return child;
  return pw.UrlLink(destination: url, child: child);
}

pw.Widget _infoCell(String label, String value, {String? url}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: _pageBg,
      border: pw.Border.all(color: _cardBorder),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _textMuted)),
        _linkedText(
          value,
          url,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: url == null ? _text : _primary,
          ),
        ),
      ],
    ),
  );
}

PdfColor _statusChipBg(TurfBookingStatus? status) {
  switch (status) {
    case TurfBookingStatus.pending:
      return PdfColor.fromInt(0xFFFFF3E0);
    case TurfBookingStatus.confirmed:
      return PdfColor.fromInt(0xFFE8F5E9);
    case TurfBookingStatus.cancelled:
      return PdfColor.fromInt(0xFFFFEBEE);
    case TurfBookingStatus.completed:
      return PdfColor.fromInt(0xFFE3F2FD);
    default:
      return PdfColor.fromInt(0xFFF3F4F6);
  }
}

PdfColor _statusChipFg(TurfBookingStatus? status) {
  switch (status) {
    case TurfBookingStatus.pending:
      return PdfColor.fromInt(0xFFE65100);
    case TurfBookingStatus.confirmed:
      return PdfColor.fromInt(0xFF1B5E20);
    case TurfBookingStatus.cancelled:
      return PdfColor.fromInt(0xFFB71C1C);
    case TurfBookingStatus.completed:
      return PdfColor.fromInt(0xFF0D47A1);
    default:
      return PdfColor.fromInt(0xFF424242);
  }
}
