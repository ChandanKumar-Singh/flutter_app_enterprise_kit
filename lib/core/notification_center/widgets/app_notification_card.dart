// ─── AppNotificationCard ──────────────────────────────────────────────────────
// Renders the correct card variant based on notification.cardVariant.
// Supports: compact / standard / rich / action / timeline / chat
// Swipe left = trailing action, swipe right = leading action (config-driven)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../config/app_notification_config.dart';
import '../controller/app_notification_controller.dart';
import '../models/app_notification_model.dart';

// ── Public entry point ────────────────────────────────────────────────────────

class AppNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final AppNotificationController controller;
  final VoidCallback? onTap;
  final bool showSwipe;
  final bool isSelected;
  final bool isBulkMode;

  const AppNotificationCard({
    super.key,
    required this.notification,
    required this.controller,
    this.onTap,
    this.showSwipe = true,
    this.isSelected = false,
    this.isBulkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = controller.config;
    Widget card = switch (notification.cardVariant) {
      AppNotificationCardVariant.compact   => _CompactCard(n: notification, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode),
      AppNotificationCardVariant.rich      => _RichCard(n: notification, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode),
      AppNotificationCardVariant.action    => _ActionCard(n: notification, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode),
      AppNotificationCardVariant.timeline  => _TimelineCard(n: notification, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode),
      AppNotificationCardVariant.chat      => _ChatCard(n: notification, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode),
      _                                    => _StandardCard(n: notification, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode),
    };

    if (cfg.enableSwipeActions && showSwipe && !isBulkMode) {
      card = _SwipeWrapper(
        notification: notification,
        controller: controller,
        swipeConfig: cfg.swipeConfig,
        child: card,
      );
    }

    return card.animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms);
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isBulkMode;
  final Widget child;

  const _CardShell({
    required this.n,
    required this.controller,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.isBulkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta   = kNotificationTypeMeta[n.type]!;
    final isUnread = !n.isRead;

    final bg = isSelected
        ? meta.accentColor.withOpacity(isDark ? 0.18 : 0.08)
        : isDark ? const Color(0xFF1E293B) : Colors.white;

    return AppCard(
      variant: AppCardVariant.outlined,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      backgroundColor: bg,
      borderRadius: BorderRadius.circular(12),
      borderColor: isSelected
          ? meta.accentColor.withOpacity(0.4)
          : isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
      padding: EdgeInsets.zero,
      onTap: () {
        if (isBulkMode) {
          controller.toggleSelection(n.id);
        } else {
          if (isUnread) controller.markRead(n.id);
          onTap?.call();
        }
      },
      onLongPress: () {
        if (!isBulkMode && controller.config.enableBulkActions) {
          controller.enterBulkMode();
          controller.toggleSelection(n.id);
        }
      },
      child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unread accent strip
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isUnread ? 3 : 0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [meta.accentColor, meta.accentColor.withOpacity(0.4)],
                    ),
                  ),
                ),
                // Bulk checkbox
                if (isBulkMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? meta.accentColor : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? meta.accentColor : (isDark ? Colors.white30 : Colors.black26),
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Iconsax.tick_circle, size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
    );
  }
}

// ── Type icon badge ────────────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final AppNotificationType type;
  final double size;

  const _TypeIcon({required this.type, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final meta   = kNotificationTypeMeta[type]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: meta.accentColor.withOpacity(isDark ? 0.18 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(meta.icon, size: size * 0.5, color: meta.accentColor),
    );
  }
}

// ── Time chip ─────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final DateTime dt;
  const _TimeChip({required this.dt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      _relativeTime(dt),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        fontSize: 11,
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Priority dot ──────────────────────────────────────────────────────────────

class _PriorityDot extends StatelessWidget {
  final AppNotificationPriority priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      AppNotificationPriority.critical => const Color(0xFFDC2626),
      AppNotificationPriority.high     => const Color(0xFFD97706),
      AppNotificationPriority.normal   => Colors.transparent,
      AppNotificationPriority.low      => Colors.transparent,
    };
    if (color == Colors.transparent) return const SizedBox.shrink();
    return Container(
      width: 6, height: 6,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Action buttons ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final List<AppNotificationAction> actions;
  final AppNotification n;
  final AppNotificationController ctrl;

  const _ActionButtons({required this.actions, required this.n, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.take(3).map((a) {
        final isDestructive = a.style == AppNotificationActionStyle.destructive;
        final isPrimary     = a.style == AppNotificationActionStyle.primary;
        final color = isDestructive
            ? const Color(0xFFDC2626)
            : isPrimary
                ? kNotificationTypeMeta[n.type]!.accentColor
                : (isDark ? Colors.white54 : const Color(0xFF64748B));
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => ctrl.markRead(n.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isPrimary
                    ? kNotificationTypeMeta[n.type]!.accentColor
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: isPrimary ? null : Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (a.icon != null) ...[
                    Icon(a.icon, size: 13, color: isPrimary ? Colors.white : color),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    a.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPrimary ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card variants
// ─────────────────────────────────────────────────────────────────────────────

// ── Compact ───────────────────────────────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;
  final VoidCallback? onTap;
  final bool isSelected, isBulkMode;

  const _CompactCard({required this.n, required this.controller, this.onTap, this.isSelected = false, this.isBulkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _CardShell(n: n, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _TypeIcon(type: n.type, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                n.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _TimeChip(dt: n.createdAt),
          ],
        ),
      ),
    );
  }
}

// ── Standard ──────────────────────────────────────────────────────────────────

class _StandardCard extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;
  final VoidCallback? onTap;
  final bool isSelected, isBulkMode;

  const _StandardCard({required this.n, required this.controller, this.onTap, this.isSelected = false, this.isBulkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta   = kNotificationTypeMeta[n.type]!;
    return _CardShell(n: n, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeIcon(type: n.type),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PriorityDot(priority: n.priority),
                      Expanded(
                        child: Text(
                          n.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (n.body != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      n.body!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: meta.accentColor.withOpacity(isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kCategoryLabel[n.category] ?? '',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: meta.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (n.isPinned) Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Iconsax.bookmark, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                      ),
                      if (n.isStarred) Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Iconsax.star, size: 12, color: const Color(0xFFD97706)),
                      ),
                      _TimeChip(dt: n.createdAt),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rich ──────────────────────────────────────────────────────────────────────

class _RichCard extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;
  final VoidCallback? onTap;
  final bool isSelected, isBulkMode;

  const _RichCard({required this.n, required this.controller, this.onTap, this.isSelected = false, this.isBulkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _CardShell(n: n, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Image.network(
                n.imageUrl!,
                height: 140, width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  child: Center(child: Icon(Iconsax.gallery_slash, color: isDark ? Colors.white30 : Colors.black26)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeIcon(type: n.type, size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(n.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _TimeChip(dt: n.createdAt),
                  ],
                ),
                if (n.body != null) ...[
                  const SizedBox(height: 6),
                  Text(n.body!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (n.actions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ActionButtons(actions: n.actions, n: n, ctrl: controller),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action ────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;
  final VoidCallback? onTap;
  final bool isSelected, isBulkMode;

  const _ActionCard({required this.n, required this.controller, this.onTap, this.isSelected = false, this.isBulkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta   = kNotificationTypeMeta[n.type]!;
    return _CardShell(n: n, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeIcon(type: n.type),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (n.body != null)
                        Text(n.body!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                _TimeChip(dt: n.createdAt),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06), height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                // Approve
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.markRead(n.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: meta.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.tick_circle, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Approve',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reject
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.archive(n.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.close_circle, size: 14, color: Color(0xFFDC2626)),
                          const SizedBox(width: 4),
                          Text('Reject',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFDC2626), fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;
  final VoidCallback? onTap;
  final bool isSelected, isBulkMode;

  const _TimelineCard({required this.n, required this.controller, this.onTap, this.isSelected = false, this.isBulkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta   = kNotificationTypeMeta[n.type]!;
    return _CardShell(n: n, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeIcon(type: n.type),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(n.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                _TimeChip(dt: n.createdAt),
              ],
            ),
            if (n.timelineSteps.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...n.timelineSteps.asMap().entries.map((e) {
                final i    = e.key;
                final step = e.value;
                final isLast = i == n.timelineSteps.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: step.isCompleted ? meta.accentColor : (isDark ? Colors.white.withOpacity(0.20) : Colors.black12),
                            border: Border.all(color: step.isCompleted ? meta.accentColor : Colors.transparent, width: 2),
                          ),
                          child: step.isCompleted
                              ? Icon(Iconsax.tick_circle, size: 8, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Container(
                            width: 1.5, height: 20,
                            color: isDark ? Colors.white.withOpacity(0.15) : Colors.black12,
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          step.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: step.isCompleted
                                ? (isDark ? Colors.white70 : const Color(0xFF374151))
                                : (isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                            fontWeight: step.isCompleted ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Chat ──────────────────────────────────────────────────────────────────────

class _ChatCard extends StatelessWidget {
  final AppNotification n;
  final AppNotificationController controller;
  final VoidCallback? onTap;
  final bool isSelected, isBulkMode;

  const _ChatCard({required this.n, required this.controller, this.onTap, this.isSelected = false, this.isBulkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sender = n.sender;
    return _CardShell(n: n, controller: controller, onTap: onTap, isSelected: isSelected, isBulkMode: isBulkMode,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    kNotificationTypeMeta[n.type]!.accentColor,
                    kNotificationTypeMeta[n.type]!.accentColor.withOpacity(0.6),
                  ],
                ),
              ),
              child: sender?.avatarUrl != null
                  ? ClipOval(child: Image.network(sender!.avatarUrl!, fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        (sender?.name.isNotEmpty == true)
                            ? sender!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (sender != null)
                        Text(sender.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: kNotificationTypeMeta[n.type]!.accentColor,
                          ),
                        ),
                      const Spacer(),
                      _TimeChip(dt: n.createdAt),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(n.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (n.body != null)
                    Text(n.body!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Swipe wrapper ─────────────────────────────────────────────────────────────

class _SwipeWrapper extends StatelessWidget {
  final AppNotification notification;
  final AppNotificationController controller;
  final AppNotificationSwipeConfig swipeConfig;
  final Widget child;

  const _SwipeWrapper({
    required this.notification,
    required this.controller,
    required this.swipeConfig,
    required this.child,
  });

  void _execute(AppNotificationSwipeAction action) {
    switch (action) {
      case AppNotificationSwipeAction.markRead:
        controller.markRead(notification.id);
      case AppNotificationSwipeAction.archive:
        controller.archive(notification.id);
      case AppNotificationSwipeAction.delete:
        controller.delete(notification.id);
      case AppNotificationSwipeAction.pin:
        controller.togglePin(notification.id);
      case AppNotificationSwipeAction.mute:
        controller.markRead(notification.id);
      case AppNotificationSwipeAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: Key('swipe_${notification.id}'),
      confirmDismiss: (dir) async {
        final action = dir == DismissDirection.startToEnd
            ? swipeConfig.leadingAction
            : swipeConfig.trailingAction;
        if (action == AppNotificationSwipeAction.none) return false;
        _execute(action);
        return action == AppNotificationSwipeAction.delete ||
               action == AppNotificationSwipeAction.archive;
      },
      background: _SwipeBackground(
        action: swipeConfig.leadingAction,
        alignment: Alignment.centerLeft,
        isDark: isDark,
      ),
      secondaryBackground: _SwipeBackground(
        action: swipeConfig.trailingAction,
        alignment: Alignment.centerRight,
        isDark: isDark,
      ),
      child: child,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final AppNotificationSwipeAction action;
  final Alignment alignment;
  final bool isDark;

  const _SwipeBackground({required this.action, required this.alignment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (action) {
      AppNotificationSwipeAction.markRead => (const Color(0xFF0284C7), Iconsax.sms_tracking, 'Mark Read'),
      AppNotificationSwipeAction.archive  => (const Color(0xFF6B7280), Iconsax.archive_1, 'Archive'),
      AppNotificationSwipeAction.delete   => (const Color(0xFFDC2626), Iconsax.trash, 'Delete'),
      AppNotificationSwipeAction.pin      => (const Color(0xFFD97706), Iconsax.bookmark, 'Pin'),
      AppNotificationSwipeAction.mute     => (const Color(0xFF7C3AED), Iconsax.volume_cross, 'Mute'),
      AppNotificationSwipeAction.none     => (Colors.transparent, Iconsax.close_circle, ''),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton card (loading placeholder) ──────────────────────────────────────

class AppNotificationSkeleton extends StatefulWidget {
  const AppNotificationSkeleton({super.key});

  @override
  State<AppNotificationSkeleton> createState() => _AppNotificationSkeletonState();
}

class _AppNotificationSkeletonState extends State<AppNotificationSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final baseColor = isDark
            ? Color.lerp(const Color(0xFF1E293B), const Color(0xFF334155), _anim.value)!
            : Color.lerp(const Color(0xFFF1F5F9), const Color(0xFFE2E8F0), _anim.value)!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: baseColor.withOpacity(0.5), shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: baseColor.withOpacity(0.5), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 160, decoration: BoxDecoration(color: baseColor.withOpacity(0.4), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class AppNotificationEmptyState extends StatelessWidget {
  final AppNotificationCategory category;
  final String? searchQuery;

  const AppNotificationEmptyState({
    super.key,
    this.category = AppNotificationCategory.all,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasSearch = searchQuery?.isNotEmpty == true;
    final icon  = hasSearch ? Iconsax.search_status : kCategoryIcon[category]!;
    final title = hasSearch ? 'No results for "$searchQuery"' : _emptyTitle(category);
    final body  = hasSearch ? 'Try a different search term' : _emptyBody(category);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: isDark ? Colors.white24 : Colors.black26),
            ),
            const SizedBox(height: 16),
            Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static String _emptyTitle(AppNotificationCategory cat) => switch (cat) {
    AppNotificationCategory.unread    => 'All caught up!',
    AppNotificationCategory.starred   => 'No starred notifications',
    AppNotificationCategory.archived  => 'Archive is empty',
    AppNotificationCategory.important => 'No important notifications',
    _                                 => 'No notifications',
  };

  static String _emptyBody(AppNotificationCategory cat) => switch (cat) {
    AppNotificationCategory.unread    => 'You have no unread notifications.',
    AppNotificationCategory.starred   => 'Star notifications to find them quickly later.',
    AppNotificationCategory.archived  => 'Archived notifications will appear here.',
    AppNotificationCategory.important => 'High priority notifications will appear here.',
    _                                 => 'New notifications will appear here.',
  };
}
