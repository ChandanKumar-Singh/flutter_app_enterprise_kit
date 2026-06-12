// ─── AppNotificationService ───────────────────────────────────────────────────
// Comprehensive local + push notification service.
//
// Responsibilities:
//   • Register Android channels on startup
//   • Request iOS/Android 13+ permission
//   • Show immediate, scheduled, and recurring notifications
//   • Receive foreground / tap / action callbacks
//   • Route notification taps to GoRouter via [onNotificationTap]
//
// Setup (in AppBootstrap.run):
//   await AppNotificationService.instance.initialize(
//     onNotificationTap: (payload) => router.go(payload.route!),
//   );
//
// Show a notification:
//   AppNotificationService.instance.show(
//     id: 1, title: 'Order Shipped', body: 'Your order is on the way!',
//     channel: AppNotificationChannel.orders,
//     payload: AppNotificationPayload.route('/orders/123'),
//   );
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:enterprise_kit/core/notifications/app_notification_channel.dart';
import 'package:enterprise_kit/core/notifications/app_notification_payload.dart';

// ── Typedefs ──────────────────────────────────────────────────────────────────

typedef NotificationTapCallback = void Function(AppNotificationPayload payload);

// ── Service ───────────────────────────────────────────────────────────────────

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  NotificationTapCallback? _onTap;

  bool _initialised = false;
  bool get isInitialised => _initialised;

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<void> initialize({
    NotificationTapCallback? onNotificationTap,
    /// Called when a notification is received while the app is in foreground.
    void Function(AppNotificationPayload payload)? onForegroundNotification,
  }) async {
    if (_initialised) return;
    _onTap = onNotificationTap;

    // Initialize timezones
    tz.initializeTimeZones();

    // 1. Register all Android channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final ch in AppNotificationChannel.values) {
        await androidPlugin.createNotificationChannel(ch.toAndroidChannel());
      }
    }

    // 2. Init settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundResponse,
    );

    _initialised = true;
    debugPrint('[AppNotificationService] Initialised ✓');
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  /// Request notification permission (iOS always, Android 13+).
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    // Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // other platforms
  }

  /// Check current permission status (Android 13+).
  Future<bool> get hasPermission async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  // ── Show ───────────────────────────────────────────────────────────────────

  /// Show an immediate notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    AppNotificationChannel channel = AppNotificationChannel.orders,
    AppNotificationPayload? payload,
    String? imageUrl,
    String? subText,
    bool ongoing = false,
    bool autoCancel = true,
  }) async {
    _ensureInit();

    final details = _buildDetails(
      channel: channel,
      imageUrl: imageUrl,
      subText: subText,
      ongoing: ongoing,
      autoCancel: autoCancel,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload?.toJson(),
    );
  }

  // ── Schedule ───────────────────────────────────────────────────────────────

  /// Show a notification at a specific [scheduledDate].
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    AppNotificationChannel channel = AppNotificationChannel.orders,
    AppNotificationPayload? payload,
    bool matchDateTimeComponents = false,
  }) async {
    _ensureInit();

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: _buildDetails(channel: channel),
      payload: payload?.toJson(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents
          ? DateTimeComponents.time
          : null,
    );
  }

  /// Schedule a daily repeating notification at [time].
  Future<void> scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required Time time,
    AppNotificationChannel channel = AppNotificationChannel.orders,
    AppNotificationPayload? payload,
  }) async {
    _ensureInit();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _buildDetails(channel: channel),
      payload: payload?.toJson(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Badge ──────────────────────────────────────────────────────────────────

  Future<void> setBadgeCount(int count) async {
    // Badge update is handled through showNotification for iOS;
    // for direct badge update use flutter_app_badger or similar.
    // This method is a hook for custom implementations.
    debugPrint('[AppNotificationService] Badge count: $count');
  }

  // ── Pending ────────────────────────────────────────────────────────────────

  Future<List<PendingNotificationRequest>> getPending() =>
      _plugin.pendingNotificationRequests();

  Future<List<ActiveNotification>> getActive() =>
      _plugin.getActiveNotifications();

  // ── Private ────────────────────────────────────────────────────────────────

  NotificationDetails _buildDetails({
    required AppNotificationChannel channel,
    String? imageUrl,
    String? subText,
    bool ongoing = false,
    bool autoCancel = true,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: channel.priority,
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
      enableLights: channel.enableLights,
      ledColor: channel.ledColor,
      ledOnMs: channel.enableLights ? 1000 : null,
      ledOffMs: channel.enableLights ? 1000 : null,
      ongoing: ongoing,
      autoCancel: autoCancel,
      subText: subText,
      styleInformation: imageUrl != null
          ? BigPictureStyleInformation(
              DrawableResourceAndroidBitmap(imageUrl),
            )
          : const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  void _handleResponse(NotificationResponse response) {
    final payloadStr = response.payload;
    if (payloadStr == null || payloadStr.isEmpty) return;

    try {
      final payload = AppNotificationPayload.fromJson(payloadStr);
      _onTap?.call(payload);
    } catch (e) {
      debugPrint('[AppNotificationService] Failed to parse payload: $e');
    }
  }

  void _ensureInit() {
    assert(
      _initialised,
      'AppNotificationService.initialize() must be called before use.',
    );
  }
}

// Background handler — must be a top-level function.
@pragma('vm:entry-point')
void _handleBackgroundResponse(NotificationResponse response) {
  // Background handling — integrate with background_fetch or workmanager
  // if cross-session background work is needed.
  debugPrint('[AppNotificationService] Background tap: ${response.payload}');
}

// ── Notification IDs ──────────────────────────────────────────────────────────
// Centralise all notification IDs to avoid collisions.

abstract class AppNotificationId {
  AppNotificationId._();

  static const orderUpdate     = 1001;
  static const paymentSuccess  = 1002;
  static const paymentFailed   = 1003;
  static const deliveryUpdate  = 1004;
  static const promoAlert      = 2001;
  static const appUpdate       = 3001;
  static const securityAlert   = 3002;
  static const dailyReminder   = 4001;
}

// ── Time helper class ────────────────────────────────────────────────────────
// Replaces the deprecated Time class from flutter_local_notifications.
class Time {
  final int hour;
  final int minute;
  final int second;

  const Time(this.hour, [this.minute = 0, this.second = 0]);
}
