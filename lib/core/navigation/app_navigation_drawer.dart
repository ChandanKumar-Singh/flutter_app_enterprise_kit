// ─── AppNavigationDrawer ─────────────────────────────────────────────────────
// Enterprise-grade animated navigation drawer.
//
// Modes:
//   Expanded  → 280px wide: full labels, sections, search, favourites, recents
//   Collapsed → 72px wide: icon-only, tooltip on hover/long-press
//
// Sections (top → bottom):
//   1. Header:     logo, app name, environment badge, tenant name
//   2. Search:     inline search field (expanded mode only)
//   3. Favourites: pinned nodes (expanded mode only)
//   4. Recents:    last N visited (expanded mode only)
//   5. Main tree:  recursive expandable tree of AppNavigationNodes
//   6. Separator
//   7. Bottom:     Settings, Help, Docs, Feedback
//   8. Profile:    avatar, name, role, email
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_navigation_node.dart';
import 'app_navigation_controller.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ── Dimension constants ───────────────────────────────────────────────────────

const _kExpandedWidth  = 272.0;
const _kCollapsedWidth = 68.0;
const _kAnimDuration   = Duration(milliseconds: 220);
const _kAnimCurve      = Curves.easeOutCubic;

// ── AppNavigationDrawer ───────────────────────────────────────────────────────

class AppNavigationDrawer extends StatefulWidget {
  final AppNavigationController controller;
  final AppNavigationEnvironment environment;
  final AppNavigationUser? user;

  /// Bottom utility nodes (Settings, Help, etc.). Shown above the profile.
  final List<AppNavigationNode> bottomNodes;

  /// Called when a navigable node is tapped.
  final void Function(AppNavigationNode node)? onNodeTap;

  const AppNavigationDrawer({
    super.key,
    required this.controller,
    required this.environment,
    this.user,
    this.bottomNodes = const [],
    this.onNodeTap,
  });

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _widthFactor;

  final List<AppNavigationNode> _navStack = [];
  String? _lastSelectedId;
  bool _isPushing = true;

  AppNavigationController get ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: _kAnimDuration,
      value: ctrl.drawerExpanded ? 1.0 : 0.0,
    );
    _widthFactor = CurvedAnimation(parent: _anim, curve: _kAnimCurve);
    ctrl.addListener(_onControllerChanged);
    _lastSelectedId = ctrl.selectedId;
    _syncNavStack();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (ctrl.drawerExpanded && _anim.value < 1) {
      _anim.forward();
    } else if (!ctrl.drawerExpanded && _anim.value > 0) {
      _anim.reverse();
    }
    if (ctrl.selectedId != _lastSelectedId) {
      _lastSelectedId = ctrl.selectedId;
      _syncNavStack();
    }
    setState(() {});
  }

  void _syncNavStack() {
    final crumbs = ctrl.breadcrumb;
    if (crumbs.isEmpty) {
      setState(() {
        _isPushing = false;
        _navStack.clear();
      });
      return;
    }
    final groupCrumbs = crumbs.where((node) => node.isGroup || node.hasChildren).toList();
    setState(() {
      _isPushing = groupCrumbs.length >= _navStack.length;
      _navStack
        ..clear()
        ..addAll(groupCrumbs);
    });
  }

  void _handleBack() {
    if (_navStack.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _isPushing = false;
        _navStack.removeLast();
      });
    }
  }

  @override
  void dispose() {
    ctrl.removeListener(_onControllerChanged);
    _anim.dispose();
    super.dispose();
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final isIncoming = child.key == ValueKey(_navStack.length);
    final Offset beginOffset;
    if (isIncoming) {
      beginOffset = _isPushing ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
    } else {
      beginOffset = _isPushing ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
    }

    return SlideTransition(
      position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _widthFactor,
      builder: (context, _) {
        final expanded = _widthFactor.value > 0.5;
        final width = _kCollapsedWidth +
            (_kExpandedWidth - _kCollapsedWidth) * _widthFactor.value;

        final List<AppNavigationNode> activeNodes;
        if (_navStack.isEmpty) {
          activeNodes = ctrl.roots;
        } else {
          activeNodes = _navStack.last.children;
        }

        return Container(
          width: width,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A)
                : cs.surfaceContainerLowest,
            border: Border(
              right: BorderSide(
                color: cs.outlineVariant.withOpacity(0.6),
              ),
            ),
          ),
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _kExpandedWidth,
                child: SafeArea(
                  top: true,
                  bottom: false,
                  child: Column(
                    children: [
                      // ── Header ────────────────────────────────────────────────────
                      _DrawerHeader(
                        environment: widget.environment,
                        controller: ctrl,
                        expanded: expanded,
                        widthFactor: _widthFactor.value,
                        navStack: _navStack,
                        onBack: _handleBack,
                      ),
        
                      // ── Search ────────────────────────────────────────────────────
                      if (expanded) ...[
                        _DrawerSearch(controller: ctrl),
                        const SizedBox(height: 4),
                      ],
        
                      // ── Main content (scrollable with transitions) ────────────────
                      Expanded(
                        child: ctrl.hasSearch
                            ? _SearchResults(
                                controller: ctrl,
                                onTap: _handleTap,
                                expanded: expanded,
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: _buildTransition,
                                child: ListView(
                                  key: ValueKey(_navStack.length),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  children: [
                                    // Favourites / Recents ONLY shown at root level
                                    if (_navStack.isEmpty) ...[
                                      if (expanded && ctrl.favouriteNodes.isNotEmpty) ...[
                                        _ShortcutSection(
                                          title: 'Favourites',
                                          icon: Iconsax.star,
                                          nodes: ctrl.favouriteNodes,
                                          controller: ctrl,
                                          onTap: _handleTap,
                                          expanded: expanded,
                                        ),
                                        const _SectionDivider(),
                                      ],
        
                                      if (expanded && ctrl.recentNodes.isNotEmpty) ...[
                                        _ShortcutSection(
                                          title: 'Recent',
                                          icon: Iconsax.clock,
                                          nodes: ctrl.recentNodes,
                                          controller: ctrl,
                                          onTap: _handleTap,
                                          expanded: expanded,
                                          trailing: InkWell(
                                            onTap: ctrl.clearRecents,
                                            borderRadius: BorderRadius.circular(4),
                                            child: Padding(
                                              padding: const EdgeInsets.all(2),
                                              child: Icon(Iconsax.close_circle,
                                                  size: 12,
                                                  color: cs.onSurfaceVariant),
                                            ),
                                          ),
                                        ),
                                        const _SectionDivider(),
                                      ],
                                    ],
        
                                    // Current active category or root listing
                                    ...activeNodes.map((node) => _NodeTile(
                                          node: node,
                                          depth: 0,
                                          controller: ctrl,
                                          onTap: _handleTap,
                                          onGroupTap: (groupNode) {
                                            setState(() {
                                              _isPushing = true;
                                              _navStack.add(groupNode);
                                            });
                                          },
                                          expanded: expanded,
                                          widthFactor: _widthFactor.value,
                                        )),
                                  ],
                                ),
                              ),
                      ),
        
                      // ── Bottom nodes ──────────────────────────────────────────────
                      if (widget.bottomNodes.isNotEmpty) ...[
                        const _SectionDivider(),
                        ...widget.bottomNodes.map((node) => _NodeTile(
                              node: node,
                              depth: 0,
                              controller: ctrl,
                              onTap: _handleTap,
                              expanded: expanded,
                              widthFactor: _widthFactor.value,
                              iconSize: 18,
                            )),
                      ],
        
                      // ── User profile ──────────────────────────────────────────────
                      if (widget.user != null) ...[
                        const _SectionDivider(),
                        _UserTile(
                          user: widget.user!,
                          expanded: expanded,
                          widthFactor: _widthFactor.value,
                        ),
                      ],
        
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(AppNavigationNode node) {
    HapticFeedback.selectionClick();
    ctrl.select(node.id);
    if (node.externalUrl != null) {
      launchUrl(Uri.parse(node.externalUrl!),
          mode: LaunchMode.externalApplication);
    } else {
      widget.onNodeTap?.call(node);
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final AppNavigationEnvironment environment;
  final AppNavigationController controller;
  final bool expanded;
  final double widthFactor;
  final List<AppNavigationNode> navStack;
  final VoidCallback onBack;

  const _DrawerHeader({
    required this.environment,
    required this.controller,
    required this.expanded,
    required this.widthFactor,
    required this.navStack,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final envColor = environment.environmentColor ??
        _envColorFor(environment.environmentLabel, cs);

    final isSubLevel = navStack.isNotEmpty;

    if (isSubLevel) {
      final currentCategory = navStack.last;
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
          ),
        ),
        child: Row(
          children: [
            // Back button
            Tooltip(
              message: 'Go back',
              child: IconButton(
                icon: const Icon(Iconsax.arrow_left, size: 20),
                onPressed: onBack,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                ),
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: 4),
              Expanded(
                child: AnimatedOpacity(
                  opacity: widthFactor,
                  duration: _kAnimDuration,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentCategory.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Section Context',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: controller.toggleDrawer,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
          ),
        ),
        child: Row(
          children: [
            // Logo / icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: environment.logoWidget ??
                  Icon(Iconsax.flash, color: cs.primary, size: 20),
            ),

            // Labels (visible when expanded)
            if (expanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedOpacity(
                  opacity: widthFactor,
                  duration: _kAnimDuration,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              environment.appName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : cs.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (environment.environmentLabel != null) ...[
                            const SizedBox(width: 6),
                            _EnvBadge(
                              label: environment.environmentLabel!,
                              color: envColor,
                            ),
                          ],
                        ],
                      ),
                      if (environment.tenantName != null)
                        Text(
                          environment.tenantName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? Colors.white38
                                : cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Toggle chevron
            AnimatedRotation(
              turns: expanded ? 0 : 0.5,
              duration: _kAnimDuration,
              child: Icon(
                Iconsax.arrow_left_2,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _envColorFor(String? label, ColorScheme cs) {
    return switch (label?.toUpperCase()) {
      'PRODUCTION' || 'PROD' => const Color(0xFF16A34A),
      'STAGING'    || 'STG'  => const Color(0xFFD97706),
      'DEV'        || 'DEVELOPMENT' => const Color(0xFF7C3AED),
      _ => cs.primary,
    };
  }
}

class _EnvBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _EnvBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Search ────────────────────────────────────────────────────────────────────

class _DrawerSearch extends StatefulWidget {
  final AppNavigationController controller;
  const _DrawerSearch({required this.controller});

  @override
  State<_DrawerSearch> createState() => _DrawerSearchState();
}

class _DrawerSearchState extends State<_DrawerSearch> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.controller.setSearchQuery,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search navigation...',
          hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          prefixIcon: Icon(Iconsax.search_normal, size: 16, color: cs.onSurfaceVariant),
          suffixIcon: widget.controller.hasSearch
              ? IconButton(
                  iconSize: 14,
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () {
                    _ctrl.clear();
                    widget.controller.clearSearch();
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: cs.surfaceContainer,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),
    );
  }
}

// ── Search results ────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final AppNavigationController controller;
  final void Function(AppNavigationNode) onTap;
  final bool expanded;

  const _SearchResults({
    required this.controller,
    required this.onTap,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final results = controller.searchResults;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No results for\n"${controller.searchQuery}"',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final node = results[i];
        final q = controller.searchQuery.toLowerCase();
        return _LeafTile(
          node: node,
          controller: controller,
          onTap: onTap,
          expanded: expanded,
          searchQuery: q,
        );
      },
    );
  }
}

// ── Shortcut section (favourites / recents) ───────────────────────────────────

class _ShortcutSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<AppNavigationNode> nodes;
  final AppNavigationController controller;
  final void Function(AppNavigationNode) onTap;
  final bool expanded;
  final Widget? trailing;

  const _ShortcutSection({
    required this.title,
    required this.icon,
    required this.nodes,
    required this.controller,
    required this.onTap,
    required this.expanded,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 10, 4),
            child: Row(
              children: [
                Icon(icon, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          ...nodes.take(5).map((n) => _LeafTile(
                node: n,
                controller: controller,
                onTap: onTap,
                expanded: expanded,
              )),
        ],
      ),
    );
  }
}

// ── Recursive node tile ───────────────────────────────────────────────────────

class _NodeTile extends StatelessWidget {
  final AppNavigationNode node;
  final int depth;
  final AppNavigationController controller;
  final void Function(AppNavigationNode) onTap;
  final void Function(AppNavigationNode)? onGroupTap;
  final bool expanded;
  final double widthFactor;
  final double iconSize;

  const _NodeTile({
    required this.node,
    required this.depth,
    required this.controller,
    required this.onTap,
    this.onGroupTap,
    required this.expanded,
    required this.widthFactor,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (node.isSeparator) return const _SectionDivider();

    if (node.isGroup || node.hasChildren) {
      return _GroupTile(
        node: node,
        depth: depth,
        controller: controller,
        onTap: onTap,
        onGroupTap: onGroupTap,
        expanded: expanded,
        widthFactor: widthFactor,
      );
    }

    return _LeafTile(
      node: node,
      controller: controller,
      onTap: onTap,
      expanded: expanded,
      depth: depth,
      iconSize: iconSize,
    );
  }
}

// ── Group tile (expandable drill-down) ────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final AppNavigationNode node;
  final int depth;
  final AppNavigationController controller;
  final void Function(AppNavigationNode) onTap;
  final void Function(AppNavigationNode)? onGroupTap;
  final bool expanded;
  final double widthFactor;

  const _GroupTile({
    required this.node,
    required this.depth,
    required this.controller,
    required this.onTap,
    this.onGroupTap,
    required this.expanded,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = node.accentColor ?? cs.primary;

    return Tooltip(
      message: expanded ? '' : node.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Material(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : cs.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InkWell(
            onTap: () {
              if (node.isNavigable) onTap(node);
              if (onGroupTap != null) {
                onGroupTap!(node);
              } else {
                controller.toggleExpanded(node.id);
              }
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.04) : cs.outlineVariant.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      node.icon ?? Iconsax.folder,
                      size: 16,
                      color: accentColor,
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: widthFactor,
                        duration: _kAnimDuration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              node.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : cs.onSurface,
                                letterSpacing: 0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (node.description != null && node.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                node.description!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant.withOpacity(0.7),
                                  fontSize: 9,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 16,
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Leaf tile ─────────────────────────────────────────────────────────────────

class _LeafTile extends StatelessWidget {
  final AppNavigationNode node;
  final AppNavigationController controller;
  final void Function(AppNavigationNode) onTap;
  final bool expanded;
  final int depth;
  final double iconSize;
  final String? searchQuery;

  const _LeafTile({
    required this.node,
    required this.controller,
    required this.onTap,
    required this.expanded,
    this.depth = 0,
    this.iconSize = 18,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isSelected = controller.selectedId == node.id;
    final isFavourite = controller.isFavourite(node.id);
    final accentColor = node.accentColor ?? cs.primary;

    return Tooltip(
      message: expanded ? '' : node.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Material(
          color: isSelected
              ? accentColor.withOpacity(isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InkWell(
            onTap: () => onTap(node),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              controller.toggleFavourite(node.id);
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withOpacity(isDark ? 0.3 : 0.15)
                      : Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  if (node.icon != null)
                    Icon(
                      node.icon,
                      size: iconSize,
                      color: isSelected ? accentColor : cs.onSurfaceVariant.withOpacity(0.8),
                    )
                  else
                    SizedBox(width: iconSize),

                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HighlightText(
                            text: node.label,
                            query: searchQuery ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? accentColor
                                  : isDark
                                      ? Colors.white70
                                      : cs.onSurface,
                            ) ?? const TextStyle(),
                            highlightStyle: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              backgroundColor: accentColor.withOpacity(0.12),
                            ),
                          ),
                          if (node.description != null && node.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              node.description!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant.withOpacity(0.6),
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (node.badge != null) _Badge(label: node.badge!),

                    if (isFavourite)
                      const Icon(Iconsax.star,
                          size: 12,
                          color: Color(0xFFD97706)),

                    if (isSelected)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: cs.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Highlight text ────────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, overflow: TextOverflow.ellipsis);
    }

    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final idx = lower.indexOf(lowerQ);

    if (idx == -1) {
      return Text(text, style: style, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: style.merge(highlightStyle),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

// ── Section divider ───────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 12,
      thickness: 1,
      indent: 12,
      endIndent: 12,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
    );
  }
}

// ── User profile tile ─────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final AppNavigationUser user;
  final bool expanded;
  final double widthFactor;

  const _UserTile({
    required this.user,
    required this.expanded,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: user.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Avatar
            _Avatar(user: user, size: 32),
            if (expanded) ...[
              const SizedBox(width: 10),
              AnimatedOpacity(
                opacity: widthFactor,
                duration: _kAnimDuration,
                child: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.role != null)
                        Text(
                          user.role!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              if (user.onTap != null)
                Icon(Iconsax.more,
                    size: 16, color: cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppNavigationUser user;
  final double size;
  const _Avatar({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (user.avatarWidget != null) {
      return SizedBox(width: size, height: size, child: user.avatarWidget!);
    }
    if (user.avatarUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(user.avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    // Initials fallback
    final initials = user.name
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}
