// ─── AppNotificationDetailPage ────────────────────────────────────────────────
// Full rich detail view for a single notification.
// Can be used as a pushed route (mobile) or embedded panel (tablet/desktop).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controller/app_notification_controller.dart';
import '../models/app_notification_model.dart';

class AppNotificationDetailPage extends StatelessWidget {
  final AppNotification notification;
  final AppNotificationController controller;
  /// When true: no Scaffold wrapper (embedded in a parent layout panel)
  final bool embedded;

  const AppNotificationDetailPage({
    super.key,
    required this.notification,
    required this.controller,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final n = controller.findById(notification.id) ?? notification;
        return _DetailBody(n: n, controller: controller);
      },
    );

    if (embedded) return body;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Notification',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          _DetailActions(n: notification, controller: controller),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        ),
      ),
      body: body,
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;

  const _DetailBody({required this.n, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta   = kNotificationTypeMeta[n.type]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero header ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: meta.accentColor.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, size: 24, color: meta.accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MetaChip(label: kCategoryLabel[n.category] ?? '', color: meta.accentColor),
                        _MetaChip(label: _priorityText(n.priority), color: _priorityColor(n.priority)),
                        if (n.isRead) _MetaChip(label: 'Read', color: const Color(0xFF059669)),
                        if (n.isPinned) _MetaChip(label: '📌 Pinned', color: const Color(0xFFD97706)),
                        if (n.isStarred) _MetaChip(label: '⭐ Starred', color: const Color(0xFFD97706)),
                      ],
                    ),
                  ],
                ),
              ),
              _DetailActions(n: n, controller: controller),
            ],
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, duration: 250.ms),

          const SizedBox(height: 20),

          // ── Rich image ──────────────────────────────────────────────────
          if (n.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                n.imageUrl!,
                width: double.infinity, height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ).animate().fadeIn(delay: 50.ms),

          if (n.imageUrl != null) const SizedBox(height: 16),

          // ── Body text ───────────────────────────────────────────────────
          if (n.body != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Text(n.body!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF374151),
                  height: 1.6,
                ),
              ),
            ).animate().fadeIn(delay: 80.ms),

          if (n.body != null) const SizedBox(height: 16),

          // ── Sender ──────────────────────────────────────────────────────
          if (n.sender != null)
            _Section(
              title: 'From',
              isDark: isDark,
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [meta.accentColor, meta.accentColor.withOpacity(0.6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(n.sender!.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.sender!.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (n.sender!.role != null)
                        Text(n.sender!.role!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Timeline ────────────────────────────────────────────────────
          if (n.timelineSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Timeline',
              isDark: isDark,
              child: Column(
                children: n.timelineSteps.asMap().entries.map((e) {
                  final step   = e.value;
                  final isLast = e.key == n.timelineSteps.length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step.isCompleted ? meta.accentColor : Colors.transparent,
                              border: Border.all(
                                color: step.isCompleted ? meta.accentColor : (isDark ? Colors.white.withOpacity(0.20) : Colors.black.withOpacity(0.15)),
                                width: 2,
                              ),
                            ),
                            child: step.isCompleted
                                ? const Icon(Iconsax.tick_circle, size: 9, color: Colors.white)
                                : null,
                          ),
                          if (!isLast) Container(width: 1.5, height: 24, color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.10)),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(step.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: step.isCompleted
                                      ? (isDark ? Colors.white : const Color(0xFF374151))
                                      : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                                  fontWeight: step.isCompleted ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              if (step.at != null)
                                Text(_formatDate(step.at!),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Actions ─────────────────────────────────────────────────────
          if (n.actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Actions',
              isDark: isDark,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: n.actions.map((a) {
                  final isDestructive = a.style == AppNotificationActionStyle.destructive;
                  final isPrimary     = a.style == AppNotificationActionStyle.primary;
                  final color = isDestructive
                      ? const Color(0xFFDC2626)
                      : isPrimary
                          ? meta.accentColor
                          : (isDark ? Colors.white54 : const Color(0xFF64748B));
                  return GestureDetector(
                    onTap: () => controller.markRead(n.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isPrimary ? meta.accentColor : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: isPrimary ? null : Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (a.icon != null) ...[
                            Icon(a.icon, size: 16, color: isPrimary ? Colors.white : color),
                            const SizedBox(width: 6),
                          ],
                          Text(a.label,
                            style: TextStyle(
                              color: isPrimary ? Colors.white : color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Metadata ─────────────────────────────────────────────────────
          const SizedBox(height: 16),
          _Section(
            title: 'Details',
            isDark: isDark,
            child: Column(
              children: [
                _MetaRow('Sent',      _formatDate(n.createdAt), isDark: isDark, theme: theme),
                if (n.readAt != null)
                  _MetaRow('Read at',   _formatDate(n.readAt!), isDark: isDark, theme: theme),
                _MetaRow('Type',      n.type.name, isDark: isDark, theme: theme),
                _MetaRow('Category',  kCategoryLabel[n.category] ?? '', isDark: isDark, theme: theme),
                _MetaRow('Priority',  _priorityText(n.priority), isDark: isDark, theme: theme),
                if (n.deepLink != null)
                  _MetaRow('Deep link', n.deepLink!, isDark: isDark, theme: theme),
                ...n.metadata.entries.map((e) =>
                  _MetaRow(e.key, '${e.value}', isDark: isDark, theme: theme)
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _priorityText(AppNotificationPriority p) => switch (p) {
    AppNotificationPriority.critical => 'Critical',
    AppNotificationPriority.high     => 'High',
    AppNotificationPriority.normal   => 'Normal',
    AppNotificationPriority.low      => 'Low',
  };

  static Color _priorityColor(AppNotificationPriority p) => switch (p) {
    AppNotificationPriority.critical => const Color(0xFFDC2626),
    AppNotificationPriority.high     => const Color(0xFFD97706),
    AppNotificationPriority.normal   => const Color(0xFF0284C7),
    AppNotificationPriority.low      => const Color(0xFF6B7280),
  };
}

// ── Shared section wrapper ────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _Section({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white30 : Colors.black38,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final ThemeData theme;

  const _MetaRow(this.label, this.value, {required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: Text(value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : const Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Inline action menu (top-right of detail) ──────────────────────────────────

class _DetailActions extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;

  const _DetailActions({required this.n, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<String>(
      icon: Icon(Iconsax.more, size: 20,
        color: isDark ? Colors.white60 : const Color(0xFF64748B)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      itemBuilder: (_) => [
        if (!n.isRead)
          _item('mark_read', 'Mark as read', Iconsax.sms_tracking),
        if (n.isRead)
          _item('mark_unread', 'Mark as unread', Iconsax.sms_notification),
        _item(n.isPinned ? 'unpin' : 'pin', n.isPinned ? 'Unpin' : 'Pin', Iconsax.bookmark),
        _item(n.isStarred ? 'unstar' : 'star', n.isStarred ? 'Remove star' : 'Star', Iconsax.star),
        if (controller.config.enableArchive && !n.isArchived)
          _item('archive', 'Archive', Iconsax.archive_1),
        const PopupMenuDivider(),
        _item('delete', 'Delete', Iconsax.trash, destructive: true),
      ],
      onSelected: (val) {
        switch (val) {
          case 'mark_read':   controller.markRead(n.id);
          case 'mark_unread': controller.markUnread(n.id);
          case 'pin':         controller.pin(n.id);
          case 'unpin':       controller.unpin(n.id);
          case 'star':        controller.toggleStar(n.id);
          case 'unstar':      controller.toggleStar(n.id);
          case 'archive':     controller.archive(n.id);
          case 'delete':      controller.delete(n.id);
        }
      },
    );
  }

  PopupMenuItem<String> _item(String val, String label, IconData icon, {bool destructive = false}) =>
    PopupMenuItem<String>(
      value: val,
      child: Row(children: [
        Icon(icon, size: 16, color: destructive ? const Color(0xFFDC2626) : null),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: destructive ? const Color(0xFFDC2626) : null, fontSize: 13)),
      ]),
    );
}
