// ─── AppNotificationPreferencesPage ──────────────────────────────────────────
// User-controllable notification preferences:
//   • Channels (push / email / sms / whatsapp / in-app)
//   • Categories (per-category on/off)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../config/app_notification_config.dart';
import '../controller/app_notification_controller.dart';
import '../models/app_notification_model.dart';

class AppNotificationPreferencesPage extends StatelessWidget {
  final AppNotificationController controller;

  const AppNotificationPreferencesPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Notification Settings',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        ),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Channels ──────────────────────────────────────────────────
            _SectionHeader(title: 'Delivery Channels', isDark: isDark),
            const SizedBox(height: 8),
            _Card(
              isDark: isDark,
              child: Column(
                children: controller.config.channels.asMap().entries.map((e) {
                  final cfg     = e.value;
                  final enabled = controller.channelEnabled(cfg.channel);
                  final isLast  = e.key == controller.config.channels.length - 1;
                  return Column(
                    children: [
                      _PrefRow(
                        icon: cfg.icon,
                        title: cfg.label,
                        subtitle: _channelSubtitle(cfg.channel),
                        value: enabled,
                        onChanged: (_) => controller.toggleChannel(cfg.channel),
                        isDark: isDark,
                      ),
                      if (!isLast) Divider(
                        height: 1,
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                        indent: 52,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Category preferences ──────────────────────────────────────
            _SectionHeader(title: 'Notification Types', isDark: isDark),
            const SizedBox(height: 4),
            Text('Choose which types of notifications you receive.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 10),
            _Card(
              isDark: isDark,
              child: Column(
                children: _categoryPrefsVisible.asMap().entries.map((e) {
                  final cat     = e.value;
                  final enabled = controller.categoryEnabled(cat);
                  final isLast  = e.key == _categoryPrefsVisible.length - 1;
                  return Column(
                    children: [
                      _PrefRow(
                        icon: kCategoryIcon[cat]!,
                        title: kCategoryLabel[cat] ?? '',
                        subtitle: _categorySubtitle(cat),
                        value: enabled,
                        onChanged: (_) => controller.toggleCategoryPref(cat),
                        isDark: isDark,
                        iconColor: _categoryColor(cat),
                      ),
                      if (!isLast) Divider(
                        height: 1,
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                        indent: 52,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick actions ──────────────────────────────────────────────
            _SectionHeader(title: 'Quick Actions', isDark: isDark),
            const SizedBox(height: 8),
            _Card(
              isDark: isDark,
              child: Column(
                children: [
                  _ActionRow(
                    icon: Icons.done_all_rounded,
                    title: 'Mark all as read',
                    subtitle: '${controller.totalUnread} unread notifications',
                    color: const Color(0xFF0284C7),
                    isDark: isDark,
                    onTap: controller.markAllRead,
                  ),
                  Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05), indent: 52),
                  _ActionRow(
                    icon: Icons.manage_search_rounded,
                    title: 'Clear recent searches',
                    subtitle: '${controller.recentSearches.length} saved searches',
                    color: const Color(0xFF7C3AED),
                    isDark: isDark,
                    onTap: controller.clearRecentSearches,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static const _categoryPrefsVisible = [
    AppNotificationCategory.security,
    AppNotificationCategory.finance,
    AppNotificationCategory.tasks,
    AppNotificationCategory.messages,
    AppNotificationCategory.updates,
    AppNotificationCategory.mentions,
    AppNotificationCategory.system,
  ];

  static String _channelSubtitle(AppNotificationChannel c) => switch (c) {
    AppNotificationChannel.push     => 'Receive alerts on your device',
    AppNotificationChannel.email    => 'Delivered to your inbox',
    AppNotificationChannel.sms      => 'Text message to your phone',
    AppNotificationChannel.whatsapp => 'Via WhatsApp',
    AppNotificationChannel.inApp    => 'Shown inside the application',
  };

  static String _categorySubtitle(AppNotificationCategory c) => switch (c) {
    AppNotificationCategory.security  => 'Login alerts, password changes',
    AppNotificationCategory.finance   => 'Payments, transactions, invoices',
    AppNotificationCategory.tasks     => 'Approvals, assignments, reminders',
    AppNotificationCategory.messages  => 'Chats, comments, mentions',
    AppNotificationCategory.updates   => 'App updates, announcements',
    AppNotificationCategory.mentions  => 'When someone mentions you',
    AppNotificationCategory.system    => 'Maintenance, system alerts',
    _                                 => '',
  };

  static Color _categoryColor(AppNotificationCategory c) => switch (c) {
    AppNotificationCategory.security  => const Color(0xFF7C3AED),
    AppNotificationCategory.finance   => const Color(0xFF059669),
    AppNotificationCategory.tasks     => const Color(0xFF0891B2),
    AppNotificationCategory.messages  => const Color(0xFF059669),
    AppNotificationCategory.updates   => const Color(0xFF6B7280),
    AppNotificationCategory.mentions  => const Color(0xFF2563EB),
    AppNotificationCategory.system    => const Color(0xFF92400E),
    _                                 => const Color(0xFF0284C7),
  };
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? Colors.white30 : Colors.black38,
      ),
    );
  }
}

// ── Card container ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      borderColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
      padding: EdgeInsets.zero,
      child: child,
    );
  }
}

// ── Preference toggle row ─────────────────────────────────────────────────────

class _PrefRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color? iconColor;

  const _PrefRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? (isDark ? Colors.white54 : const Color(0xFF6B7280));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ── Action row (destructive/utility actions) ──────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18,
              color: isDark ? Colors.white30 : Colors.black26),
          ],
        ),
      ),
    );
  }
}
