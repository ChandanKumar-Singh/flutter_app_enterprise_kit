import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:enterprise_kit/core/router/route_names.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

class ShowcaseHomePage extends StatelessWidget {
  const ShowcaseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Showcase'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _ShowcaseSection(
            title: 'UI Components',
            items: [
              _ShowcaseItem('Buttons', Icons.smart_button, RouteNames.showcaseButtons),
              _ShowcaseItem('Cards', Icons.credit_card, RouteNames.showcaseCards),
              _ShowcaseItem('Inputs', Icons.input, RouteNames.showcaseInputs),
              _ShowcaseItem('Typography', Icons.text_fields, RouteNames.showcaseTypography),
            ],
          ),
          _ShowcaseSection(
            title: 'Overlays & Feedback',
            items: [
              _ShowcaseItem('Dialogs', Icons.open_in_new, RouteNames.showcaseDialogs),
              _ShowcaseItem('Sheets', Icons.layers, RouteNames.showcaseSheets),
              _ShowcaseItem('Loaders & Shimmer', Icons.hourglass_top, RouteNames.showcaseLoaders),
              _ShowcaseItem('States', Icons.info_outline, RouteNames.showcaseStates),
            ],
          ),
          _ShowcaseSection(
            title: 'Media',
            items: [
              _ShowcaseItem('Images', Icons.image, RouteNames.showcaseImages),
              _ShowcaseItem('PDF Viewer', Icons.picture_as_pdf, RouteNames.showcasePdf),
              _ShowcaseItem('Charts', Icons.bar_chart, RouteNames.showcaseCharts),
              _ShowcaseItem('Animations', Icons.animation, RouteNames.showcaseAnimations),
            ],
          ),
          _ShowcaseSection(
            title: 'Enterprise Components (NEW)',
            items: [
              _ShowcaseItem('Toasts, Banners, Gradients', Icons.notifications_active, RouteNames.showcaseComponents),
              _ShowcaseItem('Theme Configuration', Icons.tune, RouteNames.showcaseThemeConfig),
            ],
          ),
          _ShowcaseSection(
            title: 'System',
            items: [
              _ShowcaseItem('Theme', Icons.palette, RouteNames.showcaseTheme),
              _ShowcaseItem('Network', Icons.wifi, RouteNames.showcaseNetwork),
              _ShowcaseItem('Utilities', Icons.build, RouteNames.showcaseUtils),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowcaseSection extends StatelessWidget {
  final String title;
  final List<_ShowcaseItem> items;
  const _ShowcaseSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            children: items.asMap().entries.map((e) => Column(
              children: [
                ListTile(
                  leading: Icon(e.value.icon,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(e.value.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(e.value.route),
                ),
                if (e.key < items.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _ShowcaseItem {
  final String label;
  final IconData icon;
  final String route;
  const _ShowcaseItem(this.label, this.icon, this.route);
}
