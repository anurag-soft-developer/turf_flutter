import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../core/config/constants.dart';
import '../../core/utils/phone_util.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

/// Resolves email / phone for auth screens.
///
/// - Email → returns immediately
/// - Phone with `+` country code → normalizes, no dialog
/// - Phone without code → shows [showConfirmPhoneDialog]
///
/// Returns `null` if the user cancels the confirm dialog.
Future<AuthIdentifier?> resolveAuthIdentifier(
  BuildContext context,
  String raw, {
  String defaultCountryIso = 'IN',
}) async {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Email or phone is required');
  }

  if (trimmed.contains('@')) {
    return AuthIdentifier.email(trimmed.toLowerCase());
  }

  if (hasPhoneCountryCode(trimmed)) {
    return AuthIdentifier.phone(normalizePhone(trimmed));
  }

  if (!looksLikePhone(trimmed)) {
    throw const FormatException('Enter an email or phone number');
  }

  final confirmed = await showConfirmPhoneDialog(
    context,
    initialNationalNumber: extractNationalDigits(trimmed),
    initialCountryIso: defaultCountryIso,
  );

  if (confirmed == null) return null;
  return AuthIdentifier.phone(confirmed);
}

/// Shows a dialog to confirm country code + national phone number.
///
/// Returns an E.164 phone (e.g. `+919876543210`) on confirm, or `null` if
/// dismissed / cancelled.
Future<String?> showConfirmPhoneDialog(
  BuildContext context, {
  required String initialNationalNumber,
  String initialCountryIso = 'IN',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConfirmPhoneDialog(
      initialNationalNumber: initialNationalNumber,
      initialCountryIso: initialCountryIso,
    ),
  );
}

class ConfirmPhoneDialog extends StatefulWidget {
  final String initialNationalNumber;
  final String initialCountryIso;

  const ConfirmPhoneDialog({
    super.key,
    required this.initialNationalNumber,
    this.initialCountryIso = 'IN',
  });

  @override
  State<ConfirmPhoneDialog> createState() => _ConfirmPhoneDialogState();
}

class _ConfirmPhoneDialogState extends State<ConfirmPhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late Country _country;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.initialNationalNumber,
    );
    _country =
        Country.tryParse(widget.initialCountryIso) ?? Country.parse('IN');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  IsoCode? get _destinationIso {
    try {
      return IsoCode.values.byName(_country.countryCode);
    } catch (_) {
      return null;
    }
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['IN'],
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      onSelect: (country) {
        setState(() {
          _country = country;
          _errorText = null;
        });
      },
    );
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final iso = _destinationIso;
    if (iso == null) {
      setState(() => _errorText = 'Unsupported country code');
      return;
    }

    try {
      final e164 = normalizePhone(
        _phoneController.text.trim(),
        destinationCountry: iso,
      );
      Navigator.of(context).pop(e164);
    } on FormatException catch (e) {
      setState(() => _errorText = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Confirm phone number',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(AppColors.textColor),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select your country code and confirm your phone number.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.textSecondaryColor),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Country code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickCountry,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(AppColors.surfaceColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _country.flagEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_country.name} (+${_country.phoneCode})',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(AppColors.textColor),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone number',
                hintText: 'Enter phone number',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: Color(AppColors.textSecondaryColor),
                ),
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final digits = extractNationalDigits(value);
                  if (digits.length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Color(AppColors.errorColor),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Confirm',
                onPressed: _onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
