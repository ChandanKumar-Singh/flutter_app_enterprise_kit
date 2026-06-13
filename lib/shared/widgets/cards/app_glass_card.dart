// ─── AppGlassCard ─────────────────────────────────────────────────────────────
// Multi-variant glassmorphic card — standardized from eapl TransparentGlassyCardV2.
// Auto-adapts to light/dark mode. Supports gradient, footer, glow, custom border.
//
// Variants:
//   AppGlassCard(child: ...)                  — standard surface card
//   AppGlassCard.gradient(...)                — gradient background card
//   AppGlassCard.glow(...)                    — primary color glow shadow
//   AppGlassCard.outlined(...)                — prominent border, minimal fill
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final double? height;
  final double? width;
  final double borderRadius;
  final Widget? footer;

  /// Whether to apply a backdrop blur (true glass effect — expensive on large surfaces).
  final bool blur;

  /// Primary color glow shadow.
  final bool hasGlow;
  final Color? glowColor;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.height,
    this.width,
    this.borderRadius = AppSpacing.radiusLg,
    this.footer,
    this.blur = false,
    this.hasGlow = false,
    this.glowColor,
  });

  // ── Gradient variant ──────────────────────────────────────────────────────
  const AppGlassCard.gradient({
    Key? key,
    required Widget child,
    required Gradient gradient,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? height,
    double? width,
    double borderRadius = AppSpacing.radiusLg,
    Widget? footer,
  }) : this(
          key: key,
          child: child,
          gradient: gradient,
          padding: padding,
          margin: margin,
          onTap: onTap,
          height: height,
          width: width,
          borderRadius: borderRadius,
          footer: footer,
        );

  // ── Glow variant ──────────────────────────────────────────────────────────
  const AppGlassCard.glow({
    Key? key,
    required Widget child,
    Color? glowColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? height,
    double? width,
    double borderRadius = AppSpacing.radiusLg,
    Widget? footer,
  }) : this(
          key: key,
          child: child,
          hasGlow: true,
          glowColor: glowColor,
          padding: padding,
          margin: margin,
          onTap: onTap,
          height: height,
          width: width,
          borderRadius: borderRadius,
          footer: footer,
        );

  // ── Blur variant (true glass) ─────────────────────────────────────────────
  const AppGlassCard.blur({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? height,
    double? width,
    double borderRadius = AppSpacing.radiusLg,
    Color? backgroundColor,
  }) : this(
          key: key,
          child: child,
          blur: true,
          backgroundColor: backgroundColor,
          padding: padding,
          margin: margin,
          onTap: onTap,
          height: height,
          width: width,
          borderRadius: borderRadius,
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBorderColor = borderColor ??
        (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08));

    final resolvedBackground = gradient == null
        ? backgroundColor ??
            (isDark ? const Color(0xFF1A1F3A) : cs.surface)
        : null;

    final resolvedGlow = glowColor ?? cs.primary;

    Widget card = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? resolvedBackground : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: resolvedBorderColor),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: resolvedGlow.withOpacity(0.22),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      padding: footer == null ? (padding ?? const EdgeInsets.all(16)) : null,
      child: footer == null
          ? child
          : ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                  footer!,
                ],
              ),
            ),
    );

    // Wrap with blur if requested
    if (blur) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: card,
        ),
      );
    }

    // Wrap with margin
    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      ),
    );
  }
}

// ─── AppMetricCard ────────────────────────────────────────────────────────────
// Dashboard metric card — standardized from eapl V3MetricCard.
//
// Usage:
//   AppMetricCard(label: 'Revenue', value: '₹2.4L', subValue: '+12% MoM',
//                 icon: Iconsax.trend_up, iconColor: Colors.green)

class AppMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    this.icon,
    this.iconColor,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppGlassCard(
      onTap: onTap,
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 16, color: iconColor ?? cs.primary),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 3),
            Text(
              subValue!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── AppMetricGrid ────────────────────────────────────────────────────────────
// 2-column grid of metric cards.
//
// Usage:
//   AppMetricGrid(metrics: [
//     AppMetricData(label: 'Sales', value: '₹1.2L', icon: Iconsax.shop),
//     AppMetricData(label: 'Orders', value: '348', icon: Iconsax.shopping_bag),
//   ])

class AppMetricData {
  final String label;
  final String value;
  final String? subValue;
  final IconData? icon;
  final Color? iconColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const AppMetricData({
    required this.label,
    required this.value,
    this.subValue,
    this.icon,
    this.iconColor,
    this.gradient,
    this.onTap,
  });
}

class AppMetricGrid extends StatelessWidget {
  final List<AppMetricData> metrics;
  final double spacing;
  final int crossAxisCount;

  const AppMetricGrid({
    super.key,
    required this.metrics,
    this.spacing = 12,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1.4,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, i) {
        final m = metrics[i];
        return AppMetricCard(
          label: m.label,
          value: m.value,
          subValue: m.subValue,
          icon: m.icon,
          iconColor: m.iconColor,
          gradient: m.gradient,
          onTap: m.onTap,
        );
      },
    );
  }
}
