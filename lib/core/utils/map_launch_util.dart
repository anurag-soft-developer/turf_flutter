import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/location_model.dart';
import 'exception_handler.dart';

bool canOpenLocationInMaps(LocationModel? location) {
  return _locationMapTargets(location).isNotEmpty;
}

Uri? buildLocationMapsUri(LocationModel? location) {
  final targets = _locationMapTargets(location);
  if (targets.isEmpty) return null;
  return targets.first;
}

List<Uri> _locationMapTargets(LocationModel? location) {
  if (location == null) return const [];

  final lat = location.latitude;
  final lng = location.longitude;
  if (_hasValidCoordinates(lat, lng)) {
    return [
      Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      ),
    ];
  }

  final query = _locationSearchQuery(location);
  if (query == null) return const [];

  final encoded = Uri.encodeComponent(query);
  return [
    Uri.parse('geo:0,0?q=$encoded'),
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'),
  ];
}

bool _hasValidCoordinates(double lat, double lng) {
  return lat != 0 || lng != 0;
}

String? _locationSearchQuery(LocationModel location) {
  final parts = [
    location.address,
    if ((location.city?.isNotEmpty ?? false) ||
        (location.state?.isNotEmpty ?? false))
      [
        if (location.city?.isNotEmpty ?? false) location.city,
        if (location.state?.isNotEmpty ?? false) location.state,
      ].join(', '),
  ].where((part) => part.trim().isNotEmpty);

  final query = parts.join(', ').trim();
  return query.isEmpty ? null : query;
}

Future<bool> openLocationInMaps(LocationModel? location) async {
  final targets = _locationMapTargets(location);
  if (targets.isEmpty) return false;

  for (final uri in targets) {
    if (await _tryLaunchUri(uri)) {
      return true;
    }
  }

  if (!kIsWeb && Platform.isAndroid) {
    for (final uri in targets) {
      if (await _tryLaunchAndroidIntent(uri)) {
        return true;
      }
    }
  }

  ExceptionHandler.showErrorToast('Could not open maps');
  return false;
}

Future<bool> _tryLaunchUri(Uri uri) async {
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return launched;
  } on PlatformException {
    try {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } on PlatformException {
      return false;
    }
  } catch (_) {
    return false;
  }
}

Future<bool> _tryLaunchAndroidIntent(Uri uri) async {
  try {
    final intent = AndroidIntent(
      action: 'action_view',
      data: uri.toString(),
    );
    await intent.launch();
    return true;
  } catch (_) {
    return false;
  }
}
