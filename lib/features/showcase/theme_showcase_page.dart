import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_colors.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

class ThemeShowcasePage extends StatelessWidget {
  const ThemeShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── ColorScheme ──────────────────────────────────────────────────
          _sectionTitle(context, 'ColorScheme'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _ColorChip('primary', colors.primary, colors.onPrimary),
            _ColorChip('onPrimary', colors.onPrimary, colors.primary),
            _ColorChip('primaryContainer', colors.primaryContainer, colors.onPrimaryContainer),
            _ColorChip('secondary', colors.secondary, colors.onSecondary),
            _ColorChip('secondaryContainer', colors.secondaryContainer, colors.onSecondaryContainer),
            _ColorChip('tertiary', colors.tertiary, colors.onTertiary),
            _ColorChip('error', colors.error, colors.onError),
            _ColorChip('errorContainer', colors.errorContainer, colors.onErrorContainer),
            _ColorChip('surface', colors.surface, colors.onSurface),
            _ColorChip('surfaceVariant', colors.surfaceVariant, colors.onSurfaceVariant),
            _ColorChip('outline', colors.outline, colors.surface),
            _ColorChip('shadow', colors.shadow, Colors.white),
            _ColorChip('inverseSurface', colors.inverseSurface, colors.onInverseSurface),
            _ColorChip('inversePrimary', colors.inversePrimary, colors.onSurface),
          ]),

          // ── Semantic Colors ───────────────────────────────────────────────
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Semantic Colors'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _ColorChip('success', AppColors.success, Colors.white),
            _ColorChip('warning', AppColors.warning, Colors.black),
            _ColorChip('error', AppColors.error, Colors.white),
            _ColorChip('info', AppColors.info, Colors.white),
          ]),

          // ── Typography ────────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Typography Scale'),
          ...[ 
            ('displayLarge', textTheme.displayLarge),
            ('displayMedium', textTheme.displayMedium),
            ('displaySmall', textTheme.displaySmall),
            ('headlineLarge', textTheme.headlineLarge),
            ('headlineMedium', textTheme.headlineMedium),
            ('headlineSmall', textTheme.headlineSmall),
            ('titleLarge', textTheme.titleLarge),
            ('titleMedium', textTheme.titleMedium),
            ('titleSmall', textTheme.titleSmall),
            ('bodyLarge', textTheme.bodyLarge),
            ('bodyMedium', textTheme.bodyMedium),
            ('bodySmall', textTheme.bodySmall),
            ('labelLarge', textTheme.labelLarge),
            ('labelMedium', textTheme.labelMedium),
            ('labelSmall', textTheme.labelSmall),
          ].map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(width: 150, child: Text(e.$1, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                Expanded(child: Text('The quick brown fox', style: e.$2 ?? const TextStyle())),
              ],
            ),
          )),

          // ── Spacing tokens ────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Spacing'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _SpacingTile('xs', AppSpacing.xs),
            _SpacingTile('sm', AppSpacing.sm),
            _SpacingTile('md', AppSpacing.md),
            _SpacingTile('lg', AppSpacing.lg),
            _SpacingTile('xl', AppSpacing.xl),
            _SpacingTile('xxl', AppSpacing.xxl),
          ]),

          // ── Elevation ─────────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Elevation'),
          Wrap(spacing: 16, runSpacing: 16, children: List.generate(6, (i) =>
            Card(
              elevation: i * 2.0,
              child: SizedBox(width: 60, height: 60,
                  child: Center(child: Text('${i * 2}',
                      style: const TextStyle(fontWeight: FontWeight.bold)))),
            ),
          )),

          // ── Shapes ────────────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Border Radius'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _RadiusTile('none', 0),
            _RadiusTile('xs', AppSpacing.radiusXs),
            _RadiusTile('sm', AppSpacing.radiusSm),
            _RadiusTile('md', AppSpacing.radiusMd),
            _RadiusTile('lg', AppSpacing.radiusLg),
            _RadiusTile('xl', AppSpacing.radiusXl),
            _RadiusTile('full', 100),
          ]),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
  );
}

class _ColorChip extends StatelessWidget {
  final String name;
  final Color color;
  final Color textColor;
  const _ColorChip(this.name, this.color, this.textColor);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(name, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _SpacingTile extends StatelessWidget {
  final String name;
  final double size;
  const _SpacingTile(this.name, this.size);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(width: size, height: size, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 4),
      Text('$name\n${size.toInt()}px', style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
    ],
  );
}

class _RadiusTile extends StatelessWidget {
  final String name;
  final double radius;
  const _RadiusTile(this.name, this.radius);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      const SizedBox(height: 4),
      Text(name, style: const TextStyle(fontSize: 10)),
    ],
  );
}
