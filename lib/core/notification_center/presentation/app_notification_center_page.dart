// ignore_for_file: deprecated_member_use
// ─── AppNotificationCenterPage ────────────────────────────────────────────────
// Responsive notification center:
//   < 640px   → mobile   (list only, detail as full-screen push)
//   640–1023  → tablet   (master-detail side by side)
//   ≥ 1024px  → desktop  (filter panel | list | detail — 3 columns)
//
// Search pattern (Gmail / Slack):
//   Normal:  [Notifications + badge]    🔍  ⚙️  ✓✓
//   Active:  ←  [Search notifications…]   ✕
//   Overlay: Recent searches + quick filters → suggestions → results
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../shared/search/index.dart';
import '../controller/app_notification_controller.dart';
import '../models/app_notification_model.dart';
import '../widgets/app_notification_card.dart';
import '../widgets/app_notification_filter_bar.dart';
import '../widgets/app_notification_list.dart';
import 'app_notification_detail_page.dart';
import 'app_notification_preferences_page.dart';

class AppNotificationCenterPage extends StatefulWidget {
  final AppNotificationController controller;
  final bool isLoading;

  const AppNotificationCenterPage({
    super.key,
    required this.controller,
    this.isLoading = false,
  });

  @override
  State<AppNotificationCenterPage> createState() =>
      _AppNotificationCenterPageState();
}

class _AppNotificationCenterPageState
    extends State<AppNotificationCenterPage> {
  AppNotification? _selected;

  late final AppSearchController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = AppSearchController(
      config: AppSearchConfig.notifications(),
    );
    // Wire search changes → notification filter
    _searchCtrl.onSearch = widget.controller.setSearch;
    // Wire suggestions from notification content
    _searchCtrl.onSuggest = _buildSuggestions;
  }

  void _buildSuggestions(String query) {
    final q    = query.toLowerCase();
    final all  = widget.controller.filteredNotifications;
    final suggestions = all
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            (n.body?.toLowerCase().contains(q) ?? false))
        .take(6)
        .map((n) {
      final meta = kNotificationTypeMeta[n.type]!;
      return AppSearchSuggestion(
        text:      n.title,
        subtitle:  (n.body != null && n.body!.length > 60)
                       ? '${n.body!.substring(0, 60)}…'
                       : n.body,
        icon:      meta.icon,
        iconColor: meta.accentColor,
        category:  kCategoryLabel[n.category],
      );
    }).toList();
    _searchCtrl.setSuggestions(suggestions);
  }

  void _openDetail(AppNotification n) {
    setState(() => _selected = n);
    final width = MediaQuery.sizeOf(context).width;
    final cfg   = widget.controller.config;
    // Mobile: push full screen
    if (width < cfg.tabletBreakpoint) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppNotificationDetailPage(
            notification: n,
            controller: widget.controller,
          ),
        ),
      );
    }
    // Tablet/desktop: update _selected, rendered inline
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final width = MediaQuery.sizeOf(context).width;
        final cfg   = widget.controller.config;

        if (width >= cfg.desktopBreakpoint) return _DesktopLayout(state: this);
        if (width >= cfg.tabletBreakpoint)  return _TabletLayout(state: this);
        return _MobileLayout(state: this);
      },
    );
  }
}

// ── App bar (uses AppSearchBar) ───────────────────────────────────────────────

class _NotificationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final _AppNotificationCenterPageState state;
  final bool showLeading;

  const _NotificationAppBar({required this.state, this.showLeading = false});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isDark     = theme.brightness == Brightness.dark;
    final ctrl       = state.widget.controller;
    final unread     = ctrl.totalUnread;
    final cfg        = ctrl.config;
    final iconColor  = isDark ? Colors.white60 : const Color(0xFF64748B);

    return AppSearchBar(
      controller:  state._searchCtrl,
      config:      state._searchCtrl.config,
      showLeading: showLeading,
      title: Row(
        children: [
          Text(
            'Notifications',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            _UnreadBadge(count: unread),
          ],
        ],
      ),
      actions: [
        // Mark all read
        if (unread > 0)
          IconButton(
            icon: Icon(Iconsax.tick_circle, size: 20, color: iconColor),
            tooltip: 'Mark all read',
            onPressed: ctrl.markAllRead,
          ),
        // Preferences
        if (cfg.enablePreferences)
          IconButton(
            icon: Icon(Iconsax.setting_2, size: 20, color: iconColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AppNotificationPreferencesPage(
                  controller: ctrl,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── List panel — shared by all layouts ────────────────────────────────────────
// Stack: filter bar + list below, search overlay on top when active.

class _ListPanel extends StatelessWidget {
  final _AppNotificationCenterPageState state;

  const _ListPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final ctrl   = state.widget.controller;
    final search = state._searchCtrl;
    final chips  = _buildQuickFilters(ctrl);

    return Stack(
      children: [
        Column(
          children: [
            if (ctrl.config.enableFilters)
              AppNotificationFilterBar(controller: ctrl),
            Expanded(
              child: AppNotificationList(
                controller: ctrl,
                isLoading: state.widget.isLoading,
                onTap: state._openDetail,
              ),
            ),
          ],
        ),
        // Search overlay — floats on top while search is active
        AppSearchOverlay(
          controller:   search,
          config:       search.config,
          resultCount:  search.hasQuery
              ? ctrl.filteredNotifications.length
              : null,
          quickFilters: chips,
          onFilterTap: (chip) {
            final cat = AppNotificationCategory.values.firstWhere(
              (c) => c.name == chip.id,
              orElse: () => AppNotificationCategory.all,
            );
            ctrl.setCategory(cat);
            search.exitSearchMode();
          },
        ),
      ],
    );
  }

  List<AppSearchOverlayChip> _buildQuickFilters(
      AppNotificationController ctrl) {
    const cats = [
      AppNotificationCategory.unread,
      AppNotificationCategory.important,
      AppNotificationCategory.security,
      AppNotificationCategory.finance,
      AppNotificationCategory.tasks,
      AppNotificationCategory.messages,
    ];
    return cats.map((cat) {
      final count  = ctrl.unreadFor(cat);
      final active = ctrl.activeCategory == cat;
      return AppSearchOverlayChip(
        id:       cat.name,
        label:    kCategoryLabel[cat] ?? cat.name,
        icon:     kCategoryIcon[cat],
        count:    count > 0 ? count : null,
        isActive: active,
        color:    _chipColor(cat),
      );
    }).toList();
  }

  Color _chipColor(AppNotificationCategory cat) => switch (cat) {
    AppNotificationCategory.security  => const Color(0xFF7C3AED),
    AppNotificationCategory.finance   => const Color(0xFF059669),
    AppNotificationCategory.important => const Color(0xFFD97706),
    AppNotificationCategory.unread    => const Color(0xFF2563EB),
    AppNotificationCategory.tasks     => const Color(0xFF0891B2),
    AppNotificationCategory.messages  => const Color(0xFF059669),
    _                                 => const Color(0xFF64748B),
  };
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final _AppNotificationCenterPageState state;
  const _MobileLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _NotificationAppBar(state: state, showLeading: true),
      body: _ListPanel(state: state),
    );
  }
}

// ── Tablet layout ─────────────────────────────────────────────────────────────

class _TabletLayout extends StatelessWidget {
  final _AppNotificationCenterPageState state;
  const _TabletLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final selected = state._selected;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _NotificationAppBar(state: state),
      body: Row(
        children: [
          SizedBox(
            width: 340,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: _ListPanel(state: state),
            ),
          ),
          Expanded(
            child: selected != null
                ? AppNotificationDetailPage(
                    notification: selected,
                    controller: state.widget.controller,
                    embedded: true,
                  )
                : _EmptyDetail(),
          ),
        ],
      ),
    );
  }
}

// ── Desktop layout (3-column) ─────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final _AppNotificationCenterPageState state;
  const _DesktopLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final ctrl     = state.widget.controller;
    final selected = state._selected;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
      appBar: _NotificationAppBar(state: state),
      body: Row(
        children: [
          // ── Col 1: category panel ──────────────────────────────────────
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: _CategoryPanel(controller: ctrl, state: state),
          ),

          // ── Col 2: list ────────────────────────────────────────────────
          Container(
            width: 360,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: _ListPanel(state: state),
          ),

          // ── Col 3: detail ──────────────────────────────────────────────
          Expanded(
            child: selected != null
                ? AppNotificationDetailPage(
                    notification: selected,
                    controller: ctrl,
                    embedded: true,
                  )
                : _EmptyDetail(),
          ),
        ],
      ),
    );
  }
}

// ── Desktop category panel ────────────────────────────────────────────────────

class _CategoryPanel extends StatelessWidget {
  final AppNotificationController controller;
  final _AppNotificationCenterPageState state;

  const _CategoryPanel({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cats   = controller.config.filterCategories;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'CATEGORIES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white30 : Colors.black38,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ),
        ...cats.map((cat) {
          final isActive = controller.activeCategory == cat;
          final unread   = controller.unreadFor(cat);
          return GestureDetector(
            onTap: () => controller.setCategory(cat),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    kCategoryIcon[cat]!,
                    size: 16,
                    color: isActive
                        ? theme.colorScheme.primary
                        : (isDark
                            ? Colors.white54
                            : const Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kCategoryLabel[cat] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isActive
                            ? theme.colorScheme.primary
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF374151)),
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : (isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.08)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$unread',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : (isDark ? Colors.white60 : Colors.black45),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Empty detail placeholder ──────────────────────────────────────────────────

class _EmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message_notif,
            size: 48,
            color:
                isDark ? Colors.white.withOpacity(0.15) : Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            'Select a notification',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white30 : Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
