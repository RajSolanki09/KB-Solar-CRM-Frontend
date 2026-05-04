import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    // On Flutter Web, Dio's XMLHttpRequest adapter does not support
    // sendTimeout (and warns noisily when it is non-zero). We therefore
    // only set timeout values on native platforms.
    final baseOptions = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    if (!kIsWeb) {
      baseOptions.connectTimeout = const Duration(seconds: 120);
      baseOptions.receiveTimeout = const Duration(seconds: 120);
      baseOptions.sendTimeout    = const Duration(seconds: 120);
    }

    dio = Dio(baseOptions);

    // Attach JWT to every request automatically
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await TokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // continue without header if storage fails
        }
        return handler.next(options);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          error: true,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TokenStorage
//  Single source of truth for auth token + user data.
//
//  WHY: FlutterSecureStorage silently fails on Flutter Web (Chrome) —
//       it doesn't throw, it just doesn't persist. SharedPreferences
//       works reliably on all platforms.
//
//  RULE: kIsWeb  → SharedPreferences
//        native  → FlutterSecureStorage
//
//  Usage:
//    await TokenStorage.write(token);        // after login
//    await TokenStorage.read();              // in interceptor / guards
//    await TokenStorage.delete();            // on logout
//    await TokenStorage.writeUser(jsonStr);  // save user object
//    await TokenStorage.readUser();          // restore user object
//    await TokenStorage.deleteUser();        // on logout
// ─────────────────────────────────────────────────────────────────────────────
class TokenStorage {
  static const _tokenKey = 'token';
  static const _userKey  = 'user';
  static const _secure   = FlutterSecureStorage();

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> write(String token) async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.setString(_tokenKey, token);
    } else {
      await _secure.write(key: _tokenKey, value: token);
    }
  }

  static Future<String?> read() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString(_tokenKey);
    }
    return _secure.read(key: _tokenKey);
  }

  static Future<void> delete() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.remove(_tokenKey);
    } else {
      await _secure.delete(key: _tokenKey);
    }
  }

  // ── User JSON ──────────────────────────────────────────────────────────────

  static Future<void> writeUser(String userJson) async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.setString(_userKey, userJson);
    } else {
      await _secure.write(key: _userKey, value: userJson);
    }
  }

  static Future<String?> readUser() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString(_userKey);
    }
    return _secure.read(key: _userKey);
  }

  static Future<void> deleteUser() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.remove(_userKey);
    } else {
      await _secure.delete(key: _userKey);
    }
  }

  // ── Convenience: clear everything on logout ────────────────────────────────
  static Future<void> clearAll() async {
    await delete();
    await deleteUser();
  }
}