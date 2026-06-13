// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_kit/core/theme/theme_config.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/tags/app_tag.dart';

class ThemeConfigPage extends ConsumerWidget {
  const ThemeConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(themeConfigProvider);
    final notifier = ref.read(themeConfigProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Configuration'),
        actions: [
          TextButton(
            onPressed: notifier.reset,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Theme Mode ───────────────────────────────────────────────────────
          _SectionHeader('Theme Mode'),
          _ModeSelector(config: config, notifier: notifier),
          const Divider(height: 32),

          // ── Color Presets ────────────────────────────────────────────────────
          _SectionHeader('Color Presets'),
          _ColorPresetGrid(config: config, notifier: notifier),
          const Divider(height: 32),

          // ── Custom Color ─────────────────────────────────────────────────────
          _SectionHeader('Custom Color'),
          _CustomColorRow(config: config, notifier: notifier),
          const Divider(height: 32),

          // ── Font Family ──────────────────────────────────────────────────────
          _SectionHeader('Font Family'),
          _FontSelector(config: config, notifier: notifier),
          const Divider(height: 32),

          // ── Border Radius ────────────────────────────────────────────────────
          _SectionHeader('Border Radius'),
          _RadiusSelector(config: config, notifier: notifier),
          const Divider(height: 32),

          // ── Font Scale ───────────────────────────────────────────────────────
          _SectionHeader('Font Scale (${config.fontSizeScale.toStringAsFixed(2)}x)'),
          Slider(
            value: config.fontSizeScale,
            min: 0.8,
            max: 1.3,
            divisions: 10,
            label: '${config.fontSizeScale.toStringAsFixed(2)}x',
            onChanged: notifier.setFontScale,
          ),
          const Divider(height: 32),

          // ── Visual Density ───────────────────────────────────────────────────
          _SectionHeader('Visual Density'),
          _DensitySelector(config: config, notifier: notifier),
          const Divider(height: 32),

          // ── Toggles ──────────────────────────────────────────────────────────
          _SectionHeader('Accessibility & Performance'),
          SwitchListTile(
            value: config.highContrast,
            onChanged: (_) => notifier.toggleHighContrast(),
            title: const Text('High Contrast'),
            subtitle: const Text('Increase color contrast for accessibility'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: config.reduceAnimations,
            onChanged: (_) => notifier.toggleReduceAnimations(),
            title: const Text('Reduce Animations'),
            subtitle: const Text('Use simpler transitions'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 32),

          // ── Preview ──────────────────────────────────────────────────────────
          _SectionHeader('Live Preview'),
          _ThemePreview(cs: cs, config: config),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Mode Selector ────────────────────────────────────────────────────────────
class _ModeSelector extends StatelessWidget {
  final ThemeConfig config;
  final ThemeConfigNotifier notifier;

  const _ModeSelector({required this.config, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: ThemeMode.values.map((mode) {
        final isSelected = config.mode == mode;
        final icon = switch (mode) {
          ThemeMode.light => Iconsax.sun_1,
          ThemeMode.dark => Iconsax.moon,
          _ => Iconsax.setting,
        };
        final label = switch (mode) {
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
          _ => 'System',
        };

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => notifier.setMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Color Preset Grid ────────────────────────────────────────────────────────
class _ColorPresetGrid extends StatelessWidget {
  final ThemeConfig config;
  final ThemeConfigNotifier notifier;

  const _ColorPresetGrid({required this.config, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppThemePreset.values
          .where((p) => p != AppThemePreset.custom)
          .map((preset) {
        final isSelected = config.preset == preset;
        return GestureDetector(
          onTap: () => notifier.setPreset(preset),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: preset.color,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : Border.all(color: preset.color.withOpacity(0.3), width: 1),
              boxShadow: isSelected
                  ? [BoxShadow(color: preset.color.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  const Icon(Iconsax.tick_circle, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  preset.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Custom Color Row ─────────────────────────────────────────────────────────
class _CustomColorRow extends StatelessWidget {
  final ThemeConfig config;
  final ThemeConfigNotifier notifier;

  const _CustomColorRow({required this.config, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final customColors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFFBBF24),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF6366F1),
      const Color(0xFFA855F7),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFF64748B),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: customColors.map((color) {
        final isSelected = config.preset == AppThemePreset.custom &&
            config.customColor.value == color.value;
        return GestureDetector(
          onTap: () => notifier.setCustomColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Font Selector ────────────────────────────────────────────────────────────
class _FontSelector extends StatelessWidget {
  final ThemeConfig config;
  final ThemeConfigNotifier notifier;

  const _FontSelector({required this.config, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppFontPreset.values.map((font) {
        final isSelected = config.font == font;
        return GestureDetector(
          onTap: () => notifier.setFont(font),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
              ),
            ),
            child: Text(
              font.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Radius Selector ─────────────────────────────────────────────────────────
class _RadiusSelector extends StatelessWidget {
  final ThemeConfig config;
  final ThemeConfigNotifier notifier;

  const _RadiusSelector({required this.config, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppRadiusScale.values.map((scale) {
        final isSelected = config.radiusScale == scale;
        return GestureDetector(
          onTap: () => notifier.setRadiusScale(scale),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? cs.primaryContainer : cs.surfaceVariant,
              borderRadius: BorderRadius.circular(scale.value.clamp(4, 24)),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  scale.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${scale.value.toInt()}px',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? cs.onPrimaryContainer.withOpacity(0.7)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Density Selector ─────────────────────────────────────────────────────────
class _DensitySelector extends StatelessWidget {
  final ThemeConfig config;
  final ThemeConfigNotifier notifier;

  const _DensitySelector({required this.config, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final densities = [
      (VisualDensity.compact, 'Compact'),
      (VisualDensity.standard, 'Standard'),
      (VisualDensity.comfortable, 'Comfortable'),
    ];
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: densities.map((d) {
        final isSelected = config.density == d.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => notifier.setDensity(d.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  d.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Theme Preview ────────────────────────────────────────────────────────────
class _ThemePreview extends StatelessWidget {
  final ColorScheme cs;
  final ThemeConfig config;

  const _ThemePreview({required this.cs, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(config.radiusScale.value),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview Card',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  )),
          const SizedBox(height: 8),
          Text('This is a preview of the current theme configuration.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                  ),
                  child: const Text('Primary'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppTag.success('Active'),
              AppTag.warning('Pending'),
              AppTag.error('Error'),
              const AppTag(label: 'Default'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
