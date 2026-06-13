// ─── AppNotificationCenterPage ────────────────────────────────────────────────
// Responsive notification center:
//   < 640px   → mobile   (list only, detail as full-screen push)
//   640–1023  → tablet   (master-detail side by side)
//   ≥ 1024px  → desktop  (filter panel | list | detail — 3 columns)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
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
  State<AppNotificationCenterPage> createState() => _AppNotificationCenterPageState();
}

class _AppNotificationCenterPageState extends State<AppNotificationCenterPage> {
  AppNotification? _selected;
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openDetail(AppNotification n) {
    setState(() => _selected = n);
    final w = MediaQuery.of(context).size.width;
    final cfg = widget.controller.config;
    // Mobile: push full screen
    if (w < cfg.tabletBreakpoint) {
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
    // Tablet/desktop: just update _selected (rendered inline)
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final width  = MediaQuery.of(context).size.width;
        final cfg    = widget.controller.config;

        if (width >= cfg.desktopBreakpoint) return _DesktopLayout(state: this);
        if (width >= cfg.tabletBreakpoint)  return _TabletLayout(state: this);
        return _MobileLayout(state: this);
      },
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _NotificationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final _AppNotificationCenterPageState state;
  final bool showBackButton;

  const _NotificationAppBar({required this.state, this.showBackButton = false});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final ctrl     = state.widget.controller;
    final unread   = ctrl.totalUnread;
    final cfg      = ctrl.config;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: showBackButton,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: state._searchOpen
          ? _SearchField(state: state)
          : Row(
              key: const ValueKey('title'),
              children: [
                Text('Notifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
      ),
      actions: [
        // Search toggle
        if (cfg.enableSearch)
          IconButton(
            icon: Icon(
              state._searchOpen ? Iconsax.search_status : Iconsax.search_normal,
              size: 20,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            onPressed: () {
              setState(() {
                state._searchOpen = !state._searchOpen;
                if (!state._searchOpen) {
                  state._searchCtrl.clear();
                  state.widget.controller.clearSearch();
                } else {
                  state._searchFocus.requestFocus();
                }
              });
            },
          ),

        // Mark all read
        if (ctrl.totalUnread > 0)
          IconButton(
            icon: Icon(Iconsax.tick_circle, size: 20,
              color: isDark ? Colors.white60 : const Color(0xFF64748B)),
            tooltip: 'Mark all read',
            onPressed: ctrl.markAllRead,
          ),

        // Settings
        if (cfg.enablePreferences)
          IconButton(
            icon: Icon(Iconsax.setting, size: 20,
              color: isDark ? Colors.white60 : const Color(0xFF64748B)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AppNotificationPreferencesPage(controller: ctrl)),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
    );
  }

  void setState(void Function() fn) => state.setState(fn);
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final _AppNotificationCenterPageState state;
  const _SearchField({required this.state});

  @override
  Widget build(BuildContext context) {
    return AppTextField.search(
      controller: state._searchCtrl,
      focusNode: state._searchFocus,
      hint: 'Search notifications…',
      onChanged: state.widget.controller.setSearch,
      onSubmitted: state.widget.controller.submitSearch,
    );
  }
}

// ── List panel (shared by all layouts) ───────────────────────────────────────

class _ListPanel extends StatelessWidget {
  final _AppNotificationCenterPageState state;

  const _ListPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final ctrl = state.widget.controller;
    return Column(
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
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final _AppNotificationCenterPageState state;
  const _MobileLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: _NotificationAppBar(state: state),
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
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final selected  = state._selected;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _NotificationAppBar(state: state),
      body: Row(
        children: [
          // List (left, fixed width)
          SizedBox(
            width: 340,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: _ListPanel(state: state),
            ),
          ),
          // Detail (right, fills remaining)
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
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ctrl   = state.widget.controller;
    final selected = state._selected;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
      appBar: _NotificationAppBar(state: state),
      body: Row(
        children: [
          // ── Col 1: category filter panel ────────────────────────────────
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: _CategoryPanel(controller: ctrl, state: state),
          ),

          // ── Col 2: notification list ─────────────────────────────────────
          Container(
            width: 360,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: _ListPanel(state: state),
          ),

          // ── Col 3: detail view ───────────────────────────────────────────
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
          child: Text('CATEGORIES',
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
          final meta     = kNotificationTypeMeta[AppNotificationType.info]!;
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
                        : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kCategoryLabel[cat] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isActive
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white70 : const Color(0xFF374151)),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$unread',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black45),
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
          Icon(Iconsax.info_circle, size: 48,
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.black12),
          const SizedBox(height: 12),
          Text('Select a notification',
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
