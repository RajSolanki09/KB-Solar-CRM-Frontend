import 'package:flutter/foundation.dart';

export 'api_endpoints.dart';

class ApiConstants {
  ApiConstants._();

  static const int _serverPort = 8000;
  static const String _apiPrefix = '/api';
  static const String _hostOverride = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );
  static const bool _useHttps = bool.fromEnvironment(
    'API_HTTPS',
    defaultValue: false,
  );

  static String get _scheme => _useHttps ? 'https' : 'http';

  static String get host {
    if (_hostOverride.isNotEmpty) {
      return _hostOverride;
    }

    if (kIsWeb) {
      return Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'localhost';
    }

    return 'localhost';
  }

  static String get serverUrl => '$_scheme://$host:$_serverPort';

  // ── Base URL ──────────────────────────────────────────────────────────────
  //
  //  Desktop/Web      → localhost by default
  //  Android USB debug → use adb reverse, then localhost works
  //  Android emulator  → run with --dart-define=API_HOST=10.0.2.2
  //  Physical phone WiFi → run with --dart-define=API_HOST=<your-pc-lan-ip>
  //
  static String get baseUrl => '$serverUrl$_apiPrefix';

  // ── Upload base URL (no /api suffix) ─────────────────────────────────────
  static String get uploadsUrl => '$serverUrl/uploads';

  // ── Helper: build a full image URL from a stored DB path ─────────────────
  static String imageUrl(String storedPath) {
    if (storedPath.isEmpty) return '';
    if (storedPath.startsWith('http://') || storedPath.startsWith('https://')) {
      return storedPath;
    }
    final clean = storedPath.replaceAll(r'\', '/');
    final relative = clean.startsWith('uploads/')
        ? clean.substring('uploads/'.length)
        : clean;
    return '$uploadsUrl/$relative';
  }

  static String apiPath(String path) {
    if (path.isEmpty || path == '/') return _apiPrefix;
    return path.startsWith(_apiPrefix)
        ? path
        : '$_apiPrefix${path.startsWith('/') ? path : '/$path'}';
  }
}