// ─── AppNotification — Core Domain Models ──────────────────────────────────
// All value types are @immutable. Controller owns mutable state lists.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

/// 19 semantic notification types — drives icon, color, and default priority.
enum AppNotificationType {
  info,
  success,
  warning,
  error,
  alert,
  security,
  transaction,
  payment,
  promotional,
  marketing,
  reminder,
  approval,
  assignment,
  mention,
  comment,
  chat,
  systemUpdate,
  maintenance,
  announcement,
}

/// Filter categories shown in the notification center filter bar.
enum AppNotificationCategory {
  all,
  unread,
  important,
  starred,
  archived,
  mentions,
  system,
  security,
  finance,
  tasks,
  messages,
  updates,
}

enum AppNotificationPriority { low, normal, high, critical }

enum AppNotificationCardVariant {
  compact,   // icon + title + time
  standard,  // icon + title + body + time
  rich,      // image + title + body + actions
  action,    // approve/reject inline
  timeline,  // ordered step list
  chat,      // avatar + mention style
}

enum AppNotificationSort { newest, oldest, priority, unreadFirst }

enum AppNotificationGroupBy { date, category, sender, priority, none }

// ── Action ────────────────────────────────────────────────────────────────────

enum AppNotificationActionStyle { primary, secondary, destructive }

@immutable
class AppNotificationAction {
  final String id;
  final String label;
  final IconData? icon;
  final AppNotificationActionStyle style;
  final String? deepLink;

  const AppNotificationAction({
    required this.id,
    required this.label,
    this.icon,
    this.style = AppNotificationActionStyle.primary,
    this.deepLink,
  });

  static const approve = AppNotificationAction(
    id: 'approve', label: 'Approve',
    icon: Iconsax.tick_circle,
    style: AppNotificationActionStyle.primary,
  );

  static const reject = AppNotificationAction(
    id: 'reject', label: 'Reject',
    icon: Iconsax.close_circle,
    style: AppNotificationActionStyle.destructive,
  );

  static const view = AppNotificationAction(
    id: 'view', label: 'View',
    icon: Iconsax.export,
  );
}

// ── Sender ────────────────────────────────────────────────────────────────────

@immutable
class AppNotificationSender {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;

  const AppNotificationSender({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
  });
}

// ── Timeline step (for timeline card variant) ─────────────────────────────────

@immutable
class AppNotificationTimelineStep {
  final String label;
  final DateTime? at;
  final bool isCompleted;

  const AppNotificationTimelineStep({
    required this.label,
    this.at,
    this.isCompleted = false,
  });
}

// ── Core model ────────────────────────────────────────────────────────────────

@immutable
class AppNotification {
  final String id;
  final String title;
  final String? body;
  final AppNotificationType type;
  final AppNotificationCategory category;
  final AppNotificationPriority priority;
  final AppNotificationCardVariant cardVariant;
  final AppNotificationSender? sender;

  // Media
  final String? imageUrl;
  final String? iconUrl;

  // Interactions
  final List<AppNotificationAction> actions;
  final String? deepLink;
  final Map<String, dynamic> metadata;

  // Timeline variant
  final List<AppNotificationTimelineStep> timelineSteps;

  // Timestamps
  final DateTime createdAt;
  final DateTime? expiresAt;

  // State (immutable snapshot — controller owns mutable lists)
  final bool isRead;
  final bool isArchived;
  final bool isPinned;
  final bool isStarred;
  final DateTime? readAt;

  // Smart grouping
  final String? groupKey; // same groupKey → candidates for collapsing

  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.type = AppNotificationType.info,
    this.category = AppNotificationCategory.all,
    this.priority = AppNotificationPriority.normal,
    this.cardVariant = AppNotificationCardVariant.standard,
    this.sender,
    this.imageUrl,
    this.iconUrl,
    this.actions = const [],
    this.deepLink,
    this.metadata = const {},
    this.timelineSteps = const [],
    required this.createdAt,
    this.expiresAt,
    this.isRead = false,
    this.isArchived = false,
    this.isPinned = false,
    this.isStarred = false,
    this.readAt,
    this.groupKey,
  });

  AppNotification copyWith({
    bool? isRead,
    bool? isArchived,
    bool? isPinned,
    bool? isStarred,
    DateTime? readAt,
  }) =>
      AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        category: category,
        priority: priority,
        cardVariant: cardVariant,
        sender: sender,
        imageUrl: imageUrl,
        iconUrl: iconUrl,
        actions: actions,
        deepLink: deepLink,
        metadata: metadata,
        timelineSteps: timelineSteps,
        createdAt: createdAt,
        expiresAt: expiresAt,
        isRead: isRead ?? this.isRead,
        isArchived: isArchived ?? this.isArchived,
        isPinned: isPinned ?? this.isPinned,
        isStarred: isStarred ?? this.isStarred,
        readAt: readAt ?? this.readAt,
        groupKey: groupKey,
      );
}

// ── Grouped display model ─────────────────────────────────────────────────────

/// One section (e.g. "Today", "Security") in the grouped list.
class AppNotificationGroup {
  final String label;
  final List<AppNotification> items;
  final bool isCollapsed;

  const AppNotificationGroup({
    required this.label,
    required this.items,
    this.isCollapsed = false,
  });

  AppNotificationGroup copyWith({bool? isCollapsed}) => AppNotificationGroup(
        label: label,
        items: items,
        isCollapsed: isCollapsed ?? this.isCollapsed,
      );
}

// ── Type metadata ─────────────────────────────────────────────────────────────

class AppNotificationTypeMeta {
  final Color accentColor;
  final IconData icon;
  final AppNotificationPriority defaultPriority;

  const AppNotificationTypeMeta({
    required this.accentColor,
    required this.icon,
    this.defaultPriority = AppNotificationPriority.normal,
  });
}

Map<AppNotificationType, AppNotificationTypeMeta> kNotificationTypeMeta = {
  AppNotificationType.info:        const AppNotificationTypeMeta(accentColor: Color(0xFF0284C7), icon: Iconsax.info_circle),
  AppNotificationType.success:     const AppNotificationTypeMeta(accentColor: Color(0xFF16A34A), icon: Iconsax.tick_circle),
  AppNotificationType.warning:     const AppNotificationTypeMeta(accentColor: Color(0xFFD97706), icon: Iconsax.danger, defaultPriority: AppNotificationPriority.high),
  AppNotificationType.error:       const AppNotificationTypeMeta(accentColor: Color(0xFFDC2626), icon: Iconsax.close_circle, defaultPriority: AppNotificationPriority.high),
  AppNotificationType.alert:       const AppNotificationTypeMeta(accentColor: Color(0xFFDB2777), icon: Iconsax.notification_status, defaultPriority: AppNotificationPriority.high),
  AppNotificationType.security:    const AppNotificationTypeMeta(accentColor: Color(0xFF7C3AED), icon: Iconsax.security, defaultPriority: AppNotificationPriority.critical),
  AppNotificationType.transaction: const AppNotificationTypeMeta(accentColor: Color(0xFF0891B2), icon: Iconsax.arrow_swap_horizontal),
  AppNotificationType.payment:     const AppNotificationTypeMeta(accentColor: Color(0xFF059669), icon: Iconsax.card_receive),
  AppNotificationType.promotional: const AppNotificationTypeMeta(accentColor: Color(0xFFEA580C), icon: Iconsax.tag),
  AppNotificationType.marketing:   const AppNotificationTypeMeta(accentColor: Color(0xFFD97706), icon: Iconsax.voice_square),
  AppNotificationType.reminder:    const AppNotificationTypeMeta(accentColor: Color(0xFF0284C7), icon: Iconsax.clock),
  AppNotificationType.approval:    const AppNotificationTypeMeta(accentColor: Color(0xFF7C3AED), icon: Iconsax.verify, defaultPriority: AppNotificationPriority.high),
  AppNotificationType.assignment:  const AppNotificationTypeMeta(accentColor: Color(0xFF0891B2), icon: Iconsax.briefcase),
  AppNotificationType.mention:     const AppNotificationTypeMeta(accentColor: Color(0xFF2563EB), icon: Iconsax.sms),
  AppNotificationType.comment:     const AppNotificationTypeMeta(accentColor: Color(0xFF0891B2), icon: Iconsax.message_text),
  AppNotificationType.chat:        const AppNotificationTypeMeta(accentColor: Color(0xFF059669), icon: Iconsax.messages_1),
  AppNotificationType.systemUpdate:const AppNotificationTypeMeta(accentColor: Color(0xFF6B7280), icon: Iconsax.document_download),
  AppNotificationType.maintenance: const AppNotificationTypeMeta(accentColor: Color(0xFF92400E), icon: Iconsax.setting_2, defaultPriority: AppNotificationPriority.high),
  AppNotificationType.announcement:const AppNotificationTypeMeta(accentColor: Color(0xFF1D4ED8), icon: Iconsax.voice_square),
};

const Map<AppNotificationCategory, String> kCategoryLabel = {
  AppNotificationCategory.all:       'All',
  AppNotificationCategory.unread:    'Unread',
  AppNotificationCategory.important: 'Important',
  AppNotificationCategory.starred:   'Starred',
  AppNotificationCategory.archived:  'Archived',
  AppNotificationCategory.mentions:  'Mentions',
  AppNotificationCategory.system:    'System',
  AppNotificationCategory.security:  'Security',
  AppNotificationCategory.finance:   'Finance',
  AppNotificationCategory.tasks:     'Tasks',
  AppNotificationCategory.messages:  'Messages',
  AppNotificationCategory.updates:   'Updates',
};

const Map<AppNotificationCategory, IconData> kCategoryIcon = {
  AppNotificationCategory.all:       Iconsax.notification,
  AppNotificationCategory.unread:    Iconsax.sms_notification,
  AppNotificationCategory.important: Iconsax.danger,
  AppNotificationCategory.starred:   Iconsax.star,
  AppNotificationCategory.archived:  Iconsax.archive_1,
  AppNotificationCategory.mentions:  Iconsax.sms,
  AppNotificationCategory.system:    Iconsax.setting,
  AppNotificationCategory.security:  Iconsax.security,
  AppNotificationCategory.finance:   Iconsax.empty_wallet,
  AppNotificationCategory.tasks:     Iconsax.task,
  AppNotificationCategory.messages:  Iconsax.message,
  AppNotificationCategory.updates:   Iconsax.import,
};
