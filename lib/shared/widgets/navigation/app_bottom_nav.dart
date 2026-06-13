// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Bottom Nav Item ──────────────────────────────────────────────────────────
class AppBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badgeCount;
  final bool hasDot;

  const AppBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount,
    this.hasDot = false,
  });
}

// ─── Floating Bottom Navigation ───────────────────────────────────────────────
/// Glassmorphism floating bottom nav with ink-ripple transitions.
/// Place inside a Stack at the bottom of your Scaffold body.
class AppFloatingBottomNav extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final bool blur;
  final EdgeInsets margin;

  const AppFloatingBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
    this.blur = true,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 20),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget nav = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surface.withOpacity(0.92)
            : cs.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: isDark ? cs.outlineVariant.withOpacity(0.5) : cs.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: cs.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final active = currentIndex == i;
          return Expanded(
            child: _NavItem(
              item: item,
              active: active,
              onTap: () => onIndexChanged(i),
            ),
          );
        }).toList(),
      ),
    );

    if (blur) {
      nav = ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: nav,
        ),
      );
    }

    if (margin != EdgeInsets.zero) {
      nav = Padding(
        padding: margin,
        child: nav,
      );
    }

    return SafeArea(
      child: nav,
    );
  }
}

class _NavItem extends StatefulWidget {
  final AppBottomNavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.item, required this.active, required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.active ? 1.0 : 0.0,
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      if (widget.active) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.reverse(from: 0.5),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - (_ctrl.value * 0.04),
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.active ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.active
                        ? (widget.item.activeIcon ?? widget.item.icon)
                        : widget.item.icon,
                    size: 22,
                    color: widget.active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  ),
                  if (widget.item.badgeCount != null && widget.item.badgeCount! > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.item.badgeCount! > 9 ? '9+' : '${widget.item.badgeCount}',
                            style: TextStyle(
                              color: cs.onError,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (widget.item.hasDot)
                    Positioned(
                      right: -3,
                      top: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  color: widget.active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
                child: Text(widget.item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
/// Rich section header with title, subtitle, and optional "See All" action.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? leading;
  final EdgeInsets padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 10),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Iconsax.arrow_right_3, size: 16, color: cs.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
