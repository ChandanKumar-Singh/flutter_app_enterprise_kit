// ─── AppNotificationConfig ────────────────────────────────────────────────────
// Single config object that drives the entire notification center.
// Pass it to AppNotificationController to enable/disable capabilities.
//
// Usage:
//   AppNotificationController.instance.configure(AppNotificationConfig.enterprise);
//   AppNotificationController.instance.configure(AppNotificationConfig.minimal);
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/app_notification_model.dart';

// ── Channel config ────────────────────────────────────────────────────────────

enum AppNotificationChannel { push, email, sms, whatsapp, inApp }

class AppNotificationChannelConfig {
  final AppNotificationChannel channel;
  final String label;
  final IconData icon;
  final bool enabledByDefault;

  const AppNotificationChannelConfig({
    required this.channel,
    required this.label,
    required this.icon,
    this.enabledByDefault = true,
  });

  static const push = AppNotificationChannelConfig(
    channel: AppNotificationChannel.push, label: 'Push Notifications',
    icon: Icons.notifications_rounded,
  );
  static const email = AppNotificationChannelConfig(
    channel: AppNotificationChannel.email, label: 'Email',
    icon: Icons.email_rounded,
  );
  static const sms = AppNotificationChannelConfig(
    channel: AppNotificationChannel.sms, label: 'SMS',
    icon: Icons.sms_rounded, enabledByDefault: false,
  );
  static const whatsapp = AppNotificationChannelConfig(
    channel: AppNotificationChannel.whatsapp, label: 'WhatsApp',
    icon: Icons.chat_rounded, enabledByDefault: false,
  );
  static const inApp = AppNotificationChannelConfig(
    channel: AppNotificationChannel.inApp, label: 'In-App',
    icon: Icons.web_rounded,
  );
}

// ── Swipe action config ───────────────────────────────────────────────────────

enum AppNotificationSwipeAction { markRead, archive, delete, pin, mute, none }

class AppNotificationSwipeConfig {
  final AppNotificationSwipeAction leadingAction;   // swipe right
  final AppNotificationSwipeAction trailingAction;  // swipe left

  const AppNotificationSwipeConfig({
    this.leadingAction  = AppNotificationSwipeAction.markRead,
    this.trailingAction = AppNotificationSwipeAction.archive,
  });

  static const defaultConfig = AppNotificationSwipeConfig();
  static const deleteOnLeft  = AppNotificationSwipeConfig(trailingAction: AppNotificationSwipeAction.delete);
}

// ── Main config ───────────────────────────────────────────────────────────────

class AppNotificationConfig {
  // ── Feature flags ──────────────────────────────────────────────────────────
  final bool enableSearch;
  final bool enableFilters;
  final bool enableCategories;
  final bool enableBulkActions;
  final bool enableArchive;
  final bool enablePin;
  final bool enableStar;
  final bool enableGrouping;
  final bool enableSmartGrouping;   // collapse N same-type into one row
  final bool enableAnalytics;
  final bool enablePreferences;
  final bool enableOfflineCache;
  final bool enableDeepLinks;
  final bool enableSwipeActions;
  final bool enableDigestMode;      // show "5 Transactions" instead of 5 rows
  final bool enableRichCards;
  final bool enableActionCards;
  final bool enableTimelineCards;

  // ── UX tunables ────────────────────────────────────────────────────────────
  final int pageSize;               // notifications per page load
  final int smartGroupThreshold;    // collapse if ≥ N same groupKey
  final int maxRecentSearches;
  final AppNotificationCardVariant defaultCardVariant;
  final AppNotificationSort defaultSort;
  final AppNotificationGroupBy defaultGroupBy;
  final AppNotificationSwipeConfig swipeConfig;

  // ── Visible filter categories ──────────────────────────────────────────────
  final List<AppNotificationCategory> filterCategories;

  // ── Channels shown in preferences ─────────────────────────────────────────
  final List<AppNotificationChannelConfig> channels;

  // ── Responsive layout breakpoints ─────────────────────────────────────────
  final double tabletBreakpoint;   // >= this: master-detail
  final double desktopBreakpoint;  // >= this: 3-column

  const AppNotificationConfig({
    this.enableSearch         = true,
    this.enableFilters        = true,
    this.enableCategories     = true,
    this.enableBulkActions    = true,
    this.enableArchive        = true,
    this.enablePin            = true,
    this.enableStar           = true,
    this.enableGrouping       = true,
    this.enableSmartGrouping  = true,
    this.enableAnalytics      = false,
    this.enablePreferences    = true,
    this.enableOfflineCache   = true,
    this.enableDeepLinks      = true,
    this.enableSwipeActions   = true,
    this.enableDigestMode     = false,
    this.enableRichCards      = true,
    this.enableActionCards    = true,
    this.enableTimelineCards  = true,
    this.pageSize             = 20,
    this.smartGroupThreshold  = 3,
    this.maxRecentSearches    = 8,
    this.defaultCardVariant   = AppNotificationCardVariant.standard,
    this.defaultSort          = AppNotificationSort.newest,
    this.defaultGroupBy       = AppNotificationGroupBy.date,
    this.swipeConfig          = AppNotificationSwipeConfig.defaultConfig,
    this.filterCategories     = const [
      AppNotificationCategory.all,
      AppNotificationCategory.unread,
      AppNotificationCategory.important,
      AppNotificationCategory.security,
      AppNotificationCategory.finance,
      AppNotificationCategory.tasks,
      AppNotificationCategory.messages,
      AppNotificationCategory.updates,
    ],
    this.channels = const [
      AppNotificationChannelConfig.push,
      AppNotificationChannelConfig.email,
      AppNotificationChannelConfig.sms,
      AppNotificationChannelConfig.inApp,
    ],
    this.tabletBreakpoint  = 640,
    this.desktopBreakpoint = 1024,
  });

  // ── Presets ────────────────────────────────────────────────────────────────

  /// Everything on — for full enterprise apps.
  static const enterprise = AppNotificationConfig(
    enableAnalytics: true,
    enableDigestMode: true,
    enableSmartGrouping: true,
  );

  /// Minimal — simple list, no bulk, no swipe, no preferences.
  static const minimal = AppNotificationConfig(
    enableBulkActions:   false,
    enableSwipeActions:  false,
    enablePin:           false,
    enableStar:          false,
    enableSmartGrouping: false,
    enableGrouping:      false,
    enablePreferences:   false,
    enableOfflineCache:  false,
    enableRichCards:     false,
    enableActionCards:   false,
    enableTimelineCards: false,
    defaultGroupBy:      AppNotificationGroupBy.none,
    filterCategories: [
      AppNotificationCategory.all,
      AppNotificationCategory.unread,
    ],
  );

  /// Consumer app — no analytics, no bulk, nice rich cards.
  static const consumer = AppNotificationConfig(
    enableBulkActions: false,
    enableAnalytics:   false,
    enableDigestMode:  false,
  );
}
