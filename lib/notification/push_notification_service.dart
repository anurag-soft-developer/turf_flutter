import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/models/user/user_model.dart';
import 'package:flutter_application_1/core/services/user_service.dart';
import 'package:flutter_application_1/notification/notification_inbox_cache.dart';
import 'package:flutter_application_1/notification/notification_router.dart';
import 'package:flutter_application_1/notification/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Top-level background handler (must be a top-level or static function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase may already be initialized in the background isolate.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Config missing — ignore.
  }
}

/// Registers FCM tokens with the API and handles push open / foreground display.
class PushNotificationService extends GetxService {
  static PushNotificationService get instance => Get.find();

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Turf booking and match updates',
    importance: Importance.high,
  );

  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _started = false;
  bool _firebaseReady = false;

  /// Call once from [main] after [WidgetsFlutterBinding.ensureInitialized].
  static Future<bool> initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      return true;
    } catch (e, st) {
      debugPrint('Firebase init skipped: $e\n$st');
      return false;
    }
  }

  Future<void> start() async {
    if (_started) return;

    try {
      if (Firebase.apps.isEmpty) {
        _firebaseReady = await initializeFirebase();
      } else {
        _firebaseReady = true;
      }
    } catch (_) {
      _firebaseReady = false;
    }

    if (!_firebaseReady) {
      debugPrint('PushNotificationService: Firebase not ready; push disabled');
      return;
    }

    _started = true;

    await _initLocalNotifications();
    await _requestPermission();

    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _upsertToken(token);
    }

    _tokenRefreshSub = messaging.onTokenRefresh.listen(_upsertToken);

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      // Delay so GetX navigation / auth are ready after cold start.
      unawaited(Future<void>.delayed(const Duration(milliseconds: 600), () {
        _onMessageOpened(initial);
      }));
    }
  }

  Future<void> stop() async {
    _started = false;
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _openedSub = null;

    final deviceKey = await _readDeviceKey();
    if (deviceKey != null && deviceKey.isNotEmpty) {
      try {
        await _userService.deleteFcmDevice(deviceKey);
      } catch (e) {
        debugPrint('Failed to remove FCM device on logout: $e');
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  Future<void> _requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<String> _ensureDeviceKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = AppConstants.storageKeys.fcmDeviceKey;
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    await prefs.setString(key, created);
    return created;
  }

  Future<String?> _readDeviceKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.storageKeys.fcmDeviceKey);
  }

  Future<void> _upsertToken(String token) async {
    try {
      final deviceKey = await _ensureDeviceKey();
      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'web';
      await _userService.upsertFcmDevice(
        FcmTokenEntry(
          deviceKey: deviceKey,
          token: token,
          platform: platform,
        ),
      );
    } catch (e) {
      debugPrint('FCM token upsert failed: $e');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Notification';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';

    final notificationId = message.data['notificationId']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      // Soft-update inbox if socket missed it; full doc may arrive via socket.
      NotificationInboxCache.prepend(
        NotificationInboxCache.fromPushPayload({
          ...message.data,
          'title': title,
          'body': body,
        }),
      );
    }

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: notificationId,
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final id = response.payload;
    if (id == null || id.isEmpty) return;
    unawaited(_openByNotificationId(id));
  }

  void _onMessageOpened(RemoteMessage message) {
    final id = message.data['notificationId']?.toString();
    if (id == null || id.isEmpty) return;
    unawaited(_openByNotificationId(id));
  }

  Future<void> _openByNotificationId(String notificationId) async {
    try {
      final n = await _notificationService.getOne(notificationId);
      if (n == null) return;
      await NotificationRouter.open(n);
    } catch (e) {
      debugPrint('Open notification failed: $e');
    }
  }
}
