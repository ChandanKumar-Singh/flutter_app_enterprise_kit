// ─── AppNotificationFilterBar ─────────────────────────────────────────────────
// Scrollable category chips + sort/filter/group action buttons.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../controller/app_notification_controller.dart';
import '../models/app_notification_model.dart';

class AppNotificationFilterBar extends StatelessWidget {
  final AppNotificationController controller;

  const AppNotificationFilterBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final cfg      = controller.config;
    final active   = controller.activeCategory;
    final cats     = cfg.filterCategories;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Scrollable chips ──────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat      = cats[i];
                final isActive = cat == active;
                final unread   = controller.unreadFor(cat);
                final meta     = isActive ? _activeMeta(cat) : null;

                return ChoiceChip(
                  showCheckmark: false,
                  selectedColor: isActive ? (meta?.color ?? theme.colorScheme.primary).withOpacity(0.25) : null,
                  labelStyle: isActive ? TextStyle(
                    color: meta?.color ?? theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ) : null,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(kCategoryLabel[cat] ?? ''),
                      if (unread > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (meta?.color ?? theme.colorScheme.primary)
                                : (isDark ? Colors.white.withOpacity(0.20) : Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: TextStyle(
                              color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: isActive,
                  onSelected: (_) => controller.setCategory(cat),
                );
              },
            ),
          ),

          // ── Right side: sort + filter ─────────────────────────────────────
          Container(
            width: 1, height: 24,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          _SortButton(controller: controller, isDark: isDark),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  _CategoryMeta? _activeMeta(AppNotificationCategory cat) => switch (cat) {
    AppNotificationCategory.security  => const _CategoryMeta(color: Color(0xFF7C3AED)),
    AppNotificationCategory.finance   => const _CategoryMeta(color: Color(0xFF059669)),
    AppNotificationCategory.important => const _CategoryMeta(color: Color(0xFFD97706)),
    AppNotificationCategory.unread    => const _CategoryMeta(color: Color(0xFF2563EB)),
    AppNotificationCategory.starred   => const _CategoryMeta(color: Color(0xFFD97706)),
    AppNotificationCategory.tasks     => const _CategoryMeta(color: Color(0xFF0891B2)),
    AppNotificationCategory.messages  => const _CategoryMeta(color: Color(0xFF059669)),
    _                                 => null,
  };
}

class _CategoryMeta {
  final Color color;
  const _CategoryMeta({required this.color});
}

// ── Sort/filter dropdown ──────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  final AppNotificationController controller;
  final bool isDark;

  const _SortButton({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(
        Iconsax.candle_2,
        size: 18,
        color: isDark ? Colors.white60 : const Color(0xFF64748B),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      itemBuilder: (_) => [
        _menuHeader('Sort by'),
        ...[
          AppNotificationSort.newest,
          AppNotificationSort.oldest,
          AppNotificationSort.priority,
          AppNotificationSort.unreadFirst,
        ].map((s) => PopupMenuItem<String>(
          value: 'sort_${s.name}',
          child: Row(
            children: [
              Icon(
                controller.sort == s ? Iconsax.record_circle : Iconsax.record,
                size: 16,
                color: controller.sort == s ? theme.colorScheme.primary : (isDark ? Colors.white38 : Colors.black38),
              ),
              const SizedBox(width: 8),
              Text(_sortLabel(s), style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : const Color(0xFF374151),
                fontWeight: controller.sort == s ? FontWeight.w600 : FontWeight.w400,
              )),
            ],
          ),
        )),
        const PopupMenuDivider(),
        _menuHeader('Group by'),
        ...[
          AppNotificationGroupBy.date,
          AppNotificationGroupBy.category,
          AppNotificationGroupBy.priority,
          AppNotificationGroupBy.none,
        ].map((g) => PopupMenuItem<String>(
          value: 'group_${g.name}',
          child: Row(
            children: [
              Icon(
                controller.groupBy == g ? Iconsax.record_circle : Iconsax.record,
                size: 16,
                color: controller.groupBy == g ? theme.colorScheme.primary : (isDark ? Colors.white38 : Colors.black38),
              ),
              const SizedBox(width: 8),
              Text(_groupLabel(g), style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : const Color(0xFF374151),
                fontWeight: controller.groupBy == g ? FontWeight.w600 : FontWeight.w400,
              )),
            ],
          ),
        )),
      ],
      onSelected: (val) {
        if (val.startsWith('sort_')) {
          final s = AppNotificationSort.values.firstWhere((e) => e.name == val.substring(5));
          controller.setSort(s);
        } else if (val.startsWith('group_')) {
          final g = AppNotificationGroupBy.values.firstWhere((e) => e.name == val.substring(6));
          controller.setGroupBy(g);
        }
      },
    );
  }

  static String _sortLabel(AppNotificationSort s) => switch (s) {
    AppNotificationSort.newest      => 'Newest first',
    AppNotificationSort.oldest      => 'Oldest first',
    AppNotificationSort.priority    => 'By priority',
    AppNotificationSort.unreadFirst => 'Unread first',
  };

  static String _groupLabel(AppNotificationGroupBy g) => switch (g) {
    AppNotificationGroupBy.date     => 'By date',
    AppNotificationGroupBy.category => 'By category',
    AppNotificationGroupBy.sender   => 'By sender',
    AppNotificationGroupBy.priority => 'By priority',
    AppNotificationGroupBy.none     => 'No grouping',
  };

  PopupMenuEntry<String> _menuHeader(String label) => PopupMenuItem<String>(
    enabled: false,
    height: 28,
    child: Text(label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? Colors.white30 : Colors.black38,
      ),
    ),
  );
}
