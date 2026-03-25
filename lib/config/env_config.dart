import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? '';

  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

  static String get googlePlacesApiKey =>
      dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  static String get baseApiUrl => dotenv.env['BASE_API_URL'] ?? '';

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      _validateRequiredVariables();
    } catch (e) {
      throw Exception('Failed to load environment configuration: $e');
    }
  }

  static void _validateRequiredVariables() {
    final requiredVariables = ['APP_NAME', 'GOOGLE_CLIENT_ID', 'BASE_API_URL'];

    final missingVariables = <String>[];

    for (final variable in requiredVariables) {
      final value = dotenv.env[variable];
      if (value == null || value.isEmpty) {
        missingVariables.add(variable);
      }
    }

    if (missingVariables.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingVariables.join(', ')}\n'
        'Please ensure these variables are set in your .env file',
      );
    }
  }
}
