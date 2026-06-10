import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';
import 'notification_service.dart';

/// Handles background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do — the OS will show the notification automatically.
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Callback invoked when the user taps a notification.
  /// Receives a map with keys: type, reference_id, reference_type.
  void Function(Map<String, String> data)? onNotificationTap;

  String? _currentToken;

  /// Call once after Firebase.initializeApp() and after the user is authenticated.
  Future<void> initialize() async {
    // Request permission (iOS will show a dialog, Android 13+ will too).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set up local notifications for foreground display.
    await _initLocalNotifications();

    // Listen to foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if the app was opened from a terminated state via notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }

    // Register current token.
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh.
    _messaging.onTokenRefresh.listen(_registerToken);
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Parse payload and handle tap.
        if (response.payload != null) {
          final parts = response.payload!.split('|');
          if (parts.length >= 3) {
            onNotificationTap?.call({
              'type': parts[0],
              'reference_id': parts[1],
              'reference_type': parts[2],
            });
          }
        }
      },
    );

    // Create Android notification channel.
    const channel = AndroidNotificationChannel(
      'chosen_object_notifications',
      'Notifications',
      description: 'Chosen Object notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final payload = '${data['type'] ?? ''}|${data['reference_id'] ?? ''}|${data['reference_type'] ?? ''}';

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chosen_object_notifications',
          'Notifications',
          channelDescription: 'Chosen Object notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );

    // Refresh in-app notification count.
    NotificationService.instance.fetchUnreadCount();
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    onNotificationTap?.call({
      'type': data['type']?.toString() ?? '',
      'reference_id': data['reference_id']?.toString() ?? '',
      'reference_type': data['reference_type']?.toString() ?? '',
    });
  }

  Future<void> _registerToken(String token) async {
    _currentToken = token;
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await ApiClient.instance.post('/device-tokens', {
        'fcm_token': token,
        'platform': platform,
      });
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  /// Call on logout to unregister the device token.
  Future<void> unregisterToken() async {
    if (_currentToken != null) {
      try {
        await ApiClient.instance.delete('/device-tokens/$_currentToken');
      } catch (e) {
        debugPrint('Failed to unregister FCM token: $e');
      }
      _currentToken = null;
    }
  }
}
