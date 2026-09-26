final _bearerToken = RegExp(
  r'\bBearer\s+[A-Za-z0-9\-._~+/]+=*',
  caseSensitive: false,
);
final _jwt = RegExp(
  r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
);
final _otp = RegExp(
  r'\b(otp|one[-\s]?time(?:\s+password)?|passcode|verification\s+code)\b([^0-9]{0,16})(\d{4,8})\b',
  caseSensitive: false,
);
final _phone = RegExp(r'(^|[^\d])((?:\+?\d[\s\-().]?){10,16})(?!\d)');

/// Strips bearer tokens, OTPs, and phone-like numbers from error text.
String redactSensitiveText(String input) {
  var value = input.replaceAll(_bearerToken, 'Bearer [redacted]');
  value = value.replaceAll(_jwt, '[redacted-token]');
  value = value.replaceAllMapped(_otp, (match) {
    return '${match[1]}${match[2]}[redacted]';
  });
  return value.replaceAllMapped(_phone, (match) {
    return '${match[1]}[redacted-phone]';
  });
}

String clipText(String value, int maxChars) {
  if (value.length <= maxChars) return value;
  return value.substring(0, maxChars);
}
