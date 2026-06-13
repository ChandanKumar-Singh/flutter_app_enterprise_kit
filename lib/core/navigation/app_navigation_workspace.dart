// ─── AppNavigationWorkspace ───────────────────────────────────────────────────
// Enterprise navigation shell — responsive, no nested Scaffold.
//
// Breakpoints (based on available width, not screen width):
//   < 540px   → rail hidden; hamburger button injected into the content AppBar
//   540–899px → icon-only rail (68px), auto-collapsed
//   ≥ 900px   → full expanded rail (272px)
//
// Usage:
//   Scaffold(
//     body: AppNavigationWorkspace(
//       controller: ctrl,
//       environment: ...,
//       child: MyContentPage(),
//     ),
//   )
//
// NOTE: AppNavigationWorkspace does NOT wrap content in a Scaffold.
// The parent page is responsible for providing the Scaffold.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'app_navigation_node.dart';
import 'app_navigation_controller.dart';
import 'app_navigation_drawer.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ── Breakpoints ───────────────────────────────────────────────────────────────

enum _NavLayout { hidden, iconRail, expanded }

_NavLayout _layoutFor(double width) {
  if (width < 540) return _NavLayout.hidden;
  if (width < 900) return _NavLayout.iconRail;
  return _NavLayout.expanded;
}

// ── AppNavigationWorkspace ────────────────────────────────────────────────────

class AppNavigationWorkspace extends StatefulWidget {
  final AppNavigationController controller;
  final AppNavigationEnvironment environment;
  final AppNavigationUser? user;
  final List<AppNavigationNode> bottomNodes;
  final void Function(AppNavigationNode node)? onNodeTap;

  /// Main content area. Typically a [Navigator] or a plain page widget.
  final Widget child;

  /// Show the breadcrumb bar above the content area.
  final bool showBreadcrumb;

  const AppNavigationWorkspace({
    super.key,
    required this.controller,
    required this.environment,
    required this.child,
    this.user,
    this.bottomNodes = const [],
    this.onNodeTap,
    this.showBreadcrumb = true,
  });

  @override
  State<AppNavigationWorkspace> createState() => _AppNavigationWorkspaceState();
}

class _AppNavigationWorkspaceState extends State<AppNavigationWorkspace> {
  bool _mobileDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _layoutFor(constraints.maxWidth);

        // Auto-set drawer expanded state to match the layout breakpoint
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (layout == _NavLayout.expanded &&
              !widget.controller.drawerExpanded) {
            widget.controller.setDrawerExpanded(true);
          } else if (layout == _NavLayout.iconRail &&
              widget.controller.drawerExpanded) {
            widget.controller.setDrawerExpanded(false);
          }
        });

        return layout == _NavLayout.hidden
            ? _MobileLayout(
                controller: widget.controller,
                environment: widget.environment,
                user: widget.user,
                bottomNodes: widget.bottomNodes,
                onNodeTap: widget.onNodeTap,
                showBreadcrumb: widget.showBreadcrumb,
                drawerOpen: _mobileDrawerOpen,
                onDrawerToggle: () =>
                    setState(() => _mobileDrawerOpen = !_mobileDrawerOpen),
                child: widget.child,
              )
            : _RailLayout(
                controller: widget.controller,
                environment: widget.environment,
                user: widget.user,
                bottomNodes: widget.bottomNodes,
                onNodeTap: widget.onNodeTap,
                showBreadcrumb: widget.showBreadcrumb,
                child: widget.child,
              );
      },
    );
  }
}

// ── Rail layout (tablet / desktop) ───────────────────────────────────────────

class _RailLayout extends StatelessWidget {
  final AppNavigationController controller;
  final AppNavigationEnvironment environment;
  final AppNavigationUser? user;
  final List<AppNavigationNode> bottomNodes;
  final void Function(AppNavigationNode)? onNodeTap;
  final bool showBreadcrumb;
  final Widget child;

  const _RailLayout({
    required this.controller,
    required this.environment,
    required this.user,
    required this.bottomNodes,
    required this.onNodeTap,
    required this.showBreadcrumb,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final canvasColor = isDark
        ? const Color(0xFF0B0F19) // deep slate black canvas
        : const Color(0xFFF1F5F9); // soft slate gray canvas

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Side rail ─────────────────────────────────────────────────────
        AppNavigationDrawer(
          controller: controller,
          environment: environment,
          user: user,
          bottomNodes: bottomNodes,
          onNodeTap: onNodeTap,
        ),

        // ── Content area ──────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: canvasColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBreadcrumb)
                  _BreadcrumbBar(controller: controller),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      top: showBreadcrumb ? 0.0 : AppSpacing.md,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : cs.outlineVariant.withOpacity(0.4),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mobile layout (hidden rail + overlay drawer) ──────────────────────────────

class _MobileLayout extends StatelessWidget {
  final AppNavigationController controller;
  final AppNavigationEnvironment environment;
  final AppNavigationUser? user;
  final List<AppNavigationNode> bottomNodes;
  final void Function(AppNavigationNode)? onNodeTap;
  final bool showBreadcrumb;
  final Widget child;
  final bool drawerOpen;
  final VoidCallback onDrawerToggle;

  const _MobileLayout({
    required this.controller,
    required this.environment,
    required this.user,
    required this.bottomNodes,
    required this.onNodeTap,
    required this.showBreadcrumb,
    required this.child,
    required this.drawerOpen,
    required this.onDrawerToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // ── Main content ─────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mini app bar with hamburger
            SafeArea(
              bottom: false,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(0.85),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : cs.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Iconsax.menu),
                          onPressed: onDrawerToggle,
                          tooltip: 'Open navigation',
                        ),
                        if (showBreadcrumb)
                          Expanded(
                            child: _BreadcrumbBar(
                              controller: controller,
                              compact: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
                child: child,
              ),
            ),
          ],
        ),

        // ── Overlay scrim ─────────────────────────────────────────────────
        IgnorePointer(
          ignoring: !drawerOpen,
          child: AnimatedOpacity(
            opacity: drawerOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 260),
            child: GestureDetector(
              onTap: onDrawerToggle,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Overlay drawer ────────────────────────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          left: drawerOpen ? 0 : -320,
          top: 0,
          bottom: 0,
          child: AppNavigationDrawer(
            controller: controller,
            environment: environment,
            user: user,
            bottomNodes: bottomNodes,
            onNodeTap: (node) {
              onDrawerToggle(); // close drawer on selection
              onNodeTap?.call(node);
            },
          ),
        ),
      ],
    );
  }
}

// ── Breadcrumb bar ────────────────────────────────────────────────────────────

class _BreadcrumbBar extends StatelessWidget {
  final AppNavigationController controller;
  final bool compact;

  const _BreadcrumbBar({required this.controller, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final crumbs = controller.breadcrumb;

    if (crumbs.isEmpty) return compact ? const SizedBox.shrink() : const SizedBox(height: 0);

    if (compact) {
      // Mobile: show the current node icon + label
      final current = crumbs.last;
      final color = current.accentColor ?? cs.primary;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            current.icon ?? Iconsax.category,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              current.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : cs.onSurface,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.transparent, // blends seamlessly with canvas background
      ),
      child: Row(
        children: [
          // Home / root icon
          Icon(
            Iconsax.category,
            size: 15,
            color: cs.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Icon(
            Iconsax.arrow_right_3,
            size: 14,
            color: cs.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(width: 8),
          for (int i = 0; i < crumbs.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 6),
              Icon(
                Iconsax.arrow_right_3,
                size: 14,
                color: cs.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(width: 6),
            ],
            _buildBreadcrumbItem(context, crumbs[i], i == crumbs.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(BuildContext context, AppNavigationNode crumb, bool isLast) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = crumb.accentColor ?? cs.primary;

    return Flexible(
      child: GestureDetector(
        onTap: !isLast && crumb.isNavigable
            ? () => controller.select(crumb.id)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isLast
                ? color.withOpacity(isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            border: Border.all(
              color: isLast
                  ? color.withOpacity(isDark ? 0.35 : 0.18)
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLast && crumb.icon != null) ...[
                Icon(
                  crumb.icon,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  crumb.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isLast ? color : cs.onSurfaceVariant,
                    fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── AppNavigationPage ─────────────────────────────────────────────────────────
// Convenience page body for use inside the workspace.
// Does NOT create a Scaffold — it returns a plain Column with an AppBar-like
// header and a scrollable body below it.

class AppNavigationPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;

  const AppNavigationPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page header bar
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 4,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withOpacity(0.3)
                    : cs.surface.withOpacity(0.85),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : cs.outlineVariant.withOpacity(0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : cs.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!
                          .map((action) => Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: action,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Content
        Expanded(
          child: Stack(
            children: [
              body,
              if (floatingActionButton != null)
                Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: floatingActionButton!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
