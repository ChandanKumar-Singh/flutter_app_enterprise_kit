import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:enterprise_kit/core/router/route_names.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _sections = [
    _ShowcaseEntry('Buttons', Icons.smart_button_outlined, RouteNames.showcaseButtons, Colors.blue),
    _ShowcaseEntry('Cards', Icons.credit_card_outlined, RouteNames.showcaseCards, Colors.purple),
    _ShowcaseEntry('Dialogs', Icons.dialpad_outlined, RouteNames.showcaseDialogs, Colors.teal),
    _ShowcaseEntry('Sheets', Icons.layers_outlined, RouteNames.showcaseSheets, Colors.orange),
    _ShowcaseEntry('Inputs', Icons.input_outlined, RouteNames.showcaseInputs, Colors.green),
    _ShowcaseEntry('Theme', Icons.palette_outlined, RouteNames.showcaseTheme, Colors.red),
    _ShowcaseEntry('Images', Icons.image_outlined, RouteNames.showcaseImages, Colors.indigo),
    _ShowcaseEntry('Typography', Icons.text_fields_outlined, RouteNames.showcaseTypography, Colors.brown),
    _ShowcaseEntry('Charts', Icons.bar_chart_outlined, RouteNames.showcaseCharts, Colors.cyan),
    _ShowcaseEntry('Network', Icons.wifi_outlined, RouteNames.showcaseNetwork, Colors.lime),
    _ShowcaseEntry('Utilities', Icons.build_outlined, RouteNames.showcaseUtils, Colors.amber),
    _ShowcaseEntry('Animations', Icons.animation_outlined, RouteNames.showcaseAnimations, Colors.pink),
    _ShowcaseEntry('Loaders', Icons.hourglass_empty_outlined, RouteNames.showcaseLoaders, Colors.blueGrey),
    _ShowcaseEntry('PDF', Icons.picture_as_pdf_outlined, RouteNames.showcasePdf, Colors.deepOrange),
    _ShowcaseEntry('States', Icons.layers_clear_outlined, RouteNames.showcaseStates, Colors.deepPurple),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Kit'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () {},
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primaryContainer, colors.secondaryContainer],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.layers_rounded, color: colors.onPrimary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enterprise Kit', style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                          Text('Flutter • 0 to 100', style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'A complete enterprise Flutter component library. Every widget, theme, utility, and pattern — production-ready.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.filled(
                    label: 'Explore All Components',
                    onPressed: () => context.go(RouteNames.showcase),
                    icon: const Icon(Icons.explore_outlined, size: 18),
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final s = _sections[i];
                  return _SectionTile(entry: s)
                      .animate(delay: Duration(milliseconds: 50 * i))
                      .fade(duration: 300.ms)
                      .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
                },
                childCount: _sections.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseEntry {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  const _ShowcaseEntry(this.label, this.icon, this.route, this.color);
}

class _SectionTile extends StatelessWidget {
  final _ShowcaseEntry entry;
  const _SectionTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.go(entry.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.outlineVariant),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: entry.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, color: entry.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                entry.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
