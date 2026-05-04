import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';

/// Handles FCM initialization, token registration, and foreground messages.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call once at app startup (after Firebase.initializeApp).
  Future<void> init() async {
    // Request permission (iOS / web)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // If the user denied notifications, skip all further FCM setup.
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      debugPrint('FCM: notifications not granted — skipping setup.');
      return;
    }

    // Listen for token refresh and re-register
    _messaging.onTokenRefresh.listen(_sendTokenToServer);

    // Foreground messages — just log for now
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground: \${message.notification?.title}');
    });
  }

  /// Register the device token with the backend. Call after login.
  Future<void> registerToken() async {
    try {
      // getToken() on web requires notification permission to be granted.
      // Skip silently if we don't have it.
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM: no token available (permission likely denied).');
        return;
      }
      await _sendTokenToServer(token);
    } catch (e) {
      debugPrint('FCM registerToken error: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final jwt = await TokenStorage.read();
      if (jwt == null) return;

      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      await dio.post(
        ApiEndpoints.authFcmToken,
        data: {'fcmToken': token},
        options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      );
      debugPrint('FCM token sent to server');
    } catch (e) {
      debugPrint('FCM _sendTokenToServer error: $e');
    }
  }
}