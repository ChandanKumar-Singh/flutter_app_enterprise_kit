// ─── AppNotificationChannel ───────────────────────────────────────────────────
// Android notification channel definitions.
// Each channel maps to a named Android NotificationChannel.
// iOS uses the channel importance to pick the presentation options.
//
// Add new channels here once; reference them by [AppNotificationChannel.id].
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Strongly-typed notification channel definitions.
enum AppNotificationChannel {
  /// Order status updates, delivery tracking, payment confirmations.
  /// High priority — sound + vibration.
  orders(
    id: 'orders',
    name: 'Orders & Payments',
    description: 'Real-time order status, payment confirmations, and delivery updates.',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: _kGreen,
  ),

  /// Promotional offers, discounts, new arrivals.
  /// Default priority — sound only.
  promotions(
    id: 'promotions',
    name: 'Offers & Promotions',
    description: 'Exclusive deals, discount alerts, and new arrivals.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    playSound: true,
  ),

  /// System-level alerts (app updates, security, maintenance).
  /// High priority — no marketing.
  system(
    id: 'system',
    name: 'System Alerts',
    description: 'Security alerts, forced updates, and maintenance notices.',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  ),

  /// Silent background sync, data refresh.
  /// Low priority — no sound or vibration.
  background(
    id: 'background',
    name: 'Background Sync',
    description: 'Silent background data sync notifications.',
    importance: Importance.low,
    priority: Priority.low,
    playSound: false,
    enableVibration: false,
  ),

  /// Chat / messaging — highest priority.
  messages(
    id: 'messages',
    name: 'Messages',
    description: 'Direct messages and chat notifications.',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: _kBlue,
  );

  const AppNotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.priority,
    this.playSound = true,
    this.enableVibration = false,
    this.enableLights = false,
    this.ledColor,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;
  final Priority priority;
  final bool playSound;
  final bool enableVibration;
  final bool enableLights;
  final Color? ledColor;

  /// Convert to [AndroidNotificationChannel] for registration.
  AndroidNotificationChannel toAndroidChannel() => AndroidNotificationChannel(
        id,
        name,
        description: description,
        importance: importance,
        playSound: playSound,
        enableVibration: enableVibration,
        enableLights: enableLights,
        ledColor: ledColor,
      );
}

// LED colours — only used on Android < 8 (Oreo) devices.
const _kGreen = Color(0xFF16A34A);
const _kBlue  = Color(0xFF2563EB);
