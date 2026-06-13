// ─── AppNotificationList ──────────────────────────────────────────────────────
// Grouped list with:
//   • Collapsible section headers
//   • Smart grouping (merged same-key rows)
//   • Skeleton loading
//   • Empty state
//   • Floating bulk action bar
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../controller/app_notification_controller.dart';
import '../models/app_notification_model.dart';
import 'app_notification_card.dart';

class AppNotificationList extends StatelessWidget {
  final AppNotificationController controller;
  final bool isLoading;
  final void Function(AppNotification)? onTap;

  const AppNotificationList({
    super.key,
    required this.controller,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _SkeletonList();

    final groups = controller.groups;
    final total  = groups.fold<int>(0, (sum, g) => sum + g.items.length);

    if (total == 0) {
      return AppNotificationEmptyState(
        category: controller.activeCategory,
        searchQuery: controller.searchQuery,
      );
    }

    final cfg            = controller.config;
    final hasGroupLabels = cfg.enableGrouping && groups.any((g) => g.label.isNotEmpty);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Extra top padding so content isn't hidden under search/filter
            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            if (hasGroupLabels)
              ...groups.map((g) => _SliverGroup(
                group: g,
                controller: controller,
                onTap: onTap,
              ))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final items = groups.expand((g) => g.items).toList();
                    return _itemTile(items[i]);
                  },
                  childCount: groups.expand((g) => g.items).length,
                ),
              ),

            // Space at bottom so last item isn't hidden behind bulk bar
            SliverToBoxAdapter(
              child: SizedBox(height: controller.isBulkMode ? 80 : 24),
            ),
          ],
        ),

        // Bulk action bar
        if (controller.isBulkMode && cfg.enableBulkActions)
          Positioned(
            left: 16, right: 16, bottom: 12,
            child: _BulkActionBar(controller: controller),
          ),
      ],
    );
  }

  Widget _itemTile(AppNotification n) => AppNotificationCard(
    key: ValueKey(n.id),
    notification: n,
    controller: controller,
    showSwipe: controller.config.enableSwipeActions,
    isSelected: controller.selectedIds.contains(n.id),
    isBulkMode: controller.isBulkMode,
    onTap: () => onTap?.call(n),
  );
}

// Tiny no-op Listenable for the AppNotification (immutable) fallback
class _Noop implements Listenable {
  const _Noop();
  @override void addListener(VoidCallback l) {}
  @override void removeListener(VoidCallback l) {}
}

// ── Sliver group (section header + items) ─────────────────────────────────────

class _SliverGroup extends StatelessWidget {
  final AppNotificationGroup group;
  final AppNotificationController controller;
  final void Function(AppNotification)? onTap;

  const _SliverGroup({required this.group, required this.controller, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isDark     = theme.brightness == Brightness.dark;
    final isCollapsed = controller.isGroupCollapsed(group.label);

    return SliverMainAxisGroup(
      slivers: [
        // Section header
        if (group.label.isNotEmpty)
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => controller.toggleGroupCollapse(group.label),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Text(
                      group.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${group.items.length}',
                        style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: isCollapsed ? -0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Iconsax.arrow_down_1, size: 16,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Items
        if (!isCollapsed)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final n = group.items[i];
                return AppNotificationCard(
                  key: ValueKey(n.id),
                  notification: n,
                  controller: controller,
                  showSwipe: controller.config.enableSwipeActions,
                  isSelected: controller.selectedIds.contains(n.id),
                  isBulkMode: controller.isBulkMode,
                  onTap: () => onTap?.call(n),
                );
              },
              childCount: group.items.length,
            ),
          ),
      ],
    );
  }
}

// ── Bulk action bar ───────────────────────────────────────────────────────────

class _BulkActionBar extends StatelessWidget {
  final AppNotificationController controller;
  const _BulkActionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final count  = controller.selectedCount;
    final total  = controller.filteredNotifications.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Count + select all toggle
            GestureDetector(
              onTap: count == total ? controller.clearSelection : controller.selectAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count == 0 ? 'None selected' : '$count selected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    count == total ? 'Deselect all' : 'Select all',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Actions
             _BulkButton(
              icon: Iconsax.sms_tracking,
              label: 'Read',
              onTap: count > 0 ? controller.bulkMarkRead : null,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _BulkButton(
              icon: Iconsax.archive_1,
              label: 'Archive',
              onTap: count > 0 ? controller.bulkArchive : null,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _BulkButton(
              icon: Iconsax.trash,
              label: 'Delete',
              onTap: count > 0 ? controller.bulkDelete : null,
              color: const Color(0xFFDC2626),
              isDark: isDark,
            ),
            const SizedBox(width: 8),

            // Cancel
            GestureDetector(
              onTap: controller.exitBulkMode,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.close_circle, size: 16,
                  color: isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool isDark;

  const _BulkButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? Colors.white70 : const Color(0xFF374151));
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton list ─────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (_, __) => const AppNotificationSkeleton(),
    );
  }
}
