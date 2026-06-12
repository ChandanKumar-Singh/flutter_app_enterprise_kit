// ─── AppStatusPill ────────────────────────────────────────────────────────────
// Dot + label status pill — standardized from eapl V3StatusPill.
// Supports multiple semantic variants, custom colors, scale.
//
// Usage:
//   AppStatusPill.success('Delivered')
//   AppStatusPill.error('Failed')
//   AppStatusPill.pending('In Review')
//   AppStatusPill(label: 'Custom', color: Colors.purple)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

enum AppStatusVariant { success, error, warning, info, pending, neutral, custom }

class AppStatusPill extends StatelessWidget {
  final String label;
  final Color? color;
  final AppStatusVariant variant;
  final double scale;
  final double? borderRadius;
  final bool showDot;
  final IconData? icon;

  const AppStatusPill({
    super.key,
    required this.label,
    this.color,
    this.variant = AppStatusVariant.custom,
    this.scale = 1.0,
    this.borderRadius,
    this.showDot = true,
    this.icon,
  });

  // ── Convenience constructors ──────────────────────────────────────────────

  const AppStatusPill.success(
    String label, {
    Key? key,
    double scale = 1.0,
  }) : this(
          key: key,
          label: label,
          variant: AppStatusVariant.success,
          scale: scale,
        );

  const AppStatusPill.error(
    String label, {
    Key? key,
    double scale = 1.0,
  }) : this(
          key: key,
          label: label,
          variant: AppStatusVariant.error,
          scale: scale,
        );

  const AppStatusPill.warning(
    String label, {
    Key? key,
    double scale = 1.0,
  }) : this(
          key: key,
          label: label,
          variant: AppStatusVariant.warning,
          scale: scale,
        );

  const AppStatusPill.info(
    String label, {
    Key? key,
    double scale = 1.0,
  }) : this(
          key: key,
          label: label,
          variant: AppStatusVariant.info,
          scale: scale,
        );

  const AppStatusPill.pending(
    String label, {
    Key? key,
    double scale = 1.0,
  }) : this(
          key: key,
          label: label,
          variant: AppStatusVariant.pending,
          scale: scale,
        );

  // ── Color resolution ──────────────────────────────────────────────────────

  Color _resolveColor(BuildContext context) {
    if (color != null) return color!;
    return switch (variant) {
      AppStatusVariant.success  => const Color(0xFF16A34A),
      AppStatusVariant.error    => const Color(0xFFDC2626),
      AppStatusVariant.warning  => const Color(0xFFD97706),
      AppStatusVariant.info     => const Color(0xFF2563EB),
      AppStatusVariant.pending  => const Color(0xFFD97706),
      AppStatusVariant.neutral  => Theme.of(context).colorScheme.onSurfaceVariant,
      AppStatusVariant.custom   => Theme.of(context).colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _resolveColor(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 4 * scale,
      ),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius ?? 20 * scale),
        border: Border.all(color: c.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot && icon == null) ...[
            Container(
              width: 6 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            SizedBox(width: 6 * scale),
          ] else if (icon != null) ...[
            Icon(icon, size: 12 * scale, color: c),
            SizedBox(width: 4 * scale),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AppStatusPillRow ─────────────────────────────────────────────────────────
// Horizontal row of status pills — useful for multi-attribute cards.
//
// Usage:
//   AppStatusPillRow(pills: [
//     AppStatusPill.success('Active'),
//     AppStatusPill.info('Premium'),
//   ])

class AppStatusPillRow extends StatelessWidget {
  final List<AppStatusPill> pills;
  final double spacing;

  const AppStatusPillRow({
    super.key,
    required this.pills,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing / 2,
      children: pills,
    );
  }
}
