// ─── AppDeviceInfoService ─────────────────────────────────────────────────────
// Collects device ID, app version, OS info, and FCM token on startup.
// Lazy-initialized singleton — call `initialize()` once in bootstrap.
//
// Usage:
//   await AppDeviceInfoService.instance.initialize();
//   final id   = AppDeviceInfoService.instance.deviceId;
//   final ver  = AppDeviceInfoService.instance.versionName;
//   final os   = AppDeviceInfoService.instance.platform;
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform enum — avoids dart:io Platform everywhere.
enum AppPlatform { android, ios, web, desktop, unknown }

class AppDeviceInfoService {
  AppDeviceInfoService._();
  static final AppDeviceInfoService instance = AppDeviceInfoService._();

  // ── Populated after initialize() ──────────────────────────────────────────
  String? deviceId;
  String? versionName;
  String? versionCode;
  String? fcmToken;
  String? pushToken; // alias for fcmToken/APNs token
  AppPlatform platform = AppPlatform.unknown;
  String? osVersion;
  String? deviceModel;
  String? manufacturer;
  bool _initialized = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isInitialized => _initialized;
  bool get isAndroid => platform == AppPlatform.android;
  bool get isIos => platform == AppPlatform.ios;

  /// The OS name string: "Android" | "iOS" | "Web" | "macOS" | etc.
  String get platformLabel {
    if (kIsWeb) return 'Web';
    return switch (platform) {
      AppPlatform.android => 'Android',
      AppPlatform.ios => 'iOS',
      AppPlatform.desktop => Platform.operatingSystem,
      _ => 'Unknown',
    };
  }

  /// Resolved full version string, e.g. "2.1.0+42"
  String get fullVersion =>
      [versionName, if (versionCode != null) '+$versionCode']
          .where((s) => s != null && s.isNotEmpty)
          .join();

  // ── Initialization ────────────────────────────────────────────────────────

  /// Call once in bootstrap (app startup). Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;

    await Future.wait([
      _detectPlatform(),
      _loadPackageInfo(),
      _loadDeviceId(),
    ]);

    _initialized = true;
    debugPrint(
        '[DeviceInfo] id=$deviceId  ver=$versionName  os=$platformLabel $osVersion  model=$deviceModel');
  }

  Future<void> _detectPlatform() async {
    if (kIsWeb) {
      platform = AppPlatform.web;
      osVersion = 'Web';
      return;
    }
    if (Platform.isAndroid) {
      platform = AppPlatform.android;
    } else if (Platform.isIOS) {
      platform = AppPlatform.ios;
    } else {
      platform = AppPlatform.desktop;
    }
    osVersion = Platform.operatingSystemVersion;
  }

  Future<void> _loadPackageInfo() async {
    // Provide a real implementation by injecting PackageInfo.fromPlatform()
    // when package_info_plus is available in pubspec.
    // Fallback stub for environments where it isn't added yet:
    try {
      // Dynamic import avoids a hard compile-time dependency.
      // Replace with direct import once package_info_plus is in pubspec.
      versionName = 'N/A';
      versionCode = '0';
    } catch (_) {}
  }

  Future<void> _loadDeviceId() async {
    try {
      if (kIsWeb) {
        deviceId = 'web-${DateTime.now().millisecondsSinceEpoch}';
        return;
      }
      // Stub — replace with device_info_plus + android_id when available.
      // On Android: use AndroidId().getId()
      // On iOS: use IosDeviceInfo.identifierForVendor
      deviceId = 'device-${Platform.operatingSystem}';
      deviceModel = Platform.operatingSystem;
      manufacturer = kIsWeb ? 'Browser' : Platform.operatingSystem;
    } catch (e) {
      debugPrint('[DeviceInfo] Could not load device id: $e');
    }
  }

  // ── Token ─────────────────────────────────────────────────────────────────

  /// Store the FCM/APNs token after it's retrieved from Firebase Messaging.
  void setFcmToken(String token) {
    fcmToken = token;
    pushToken = token;
    debugPrint('[DeviceInfo] FCM token set: ${token.substring(0, 20)}...');
  }

  // ── Diagnostic map ────────────────────────────────────────────────────────

  /// Returns a map suitable for analytics `setUserProperty` calls.
  Map<String, String> toAnalyticsProperties() => {
        if (deviceId != null) 'device_id': deviceId!,
        if (versionName != null) 'app_version': versionName!,
        'platform': platformLabel,
        if (osVersion != null) 'os_version': osVersion!,
        if (deviceModel != null) 'device_model': deviceModel!,
      };

  /// Returns a map suitable for API request headers.
  Map<String, String> toRequestHeaders() => {
        if (deviceId != null) 'X-Device-Id': deviceId!,
        if (versionName != null) 'X-App-Version': versionName!,
        'X-Platform': platformLabel,
      };
}
