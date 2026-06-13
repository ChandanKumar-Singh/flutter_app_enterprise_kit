// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:enterprise_kit/core/router/route_names.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
// RouteNames.showcaseUiKit is used below

class ShowcaseHomePage extends StatelessWidget {
  const ShowcaseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Gradient SliverAppBar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            floating: false,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 1,
            flexibleSpace: LayoutBuilder(
              builder: (ctx, constraints) {
                final double currentHeight = constraints.biggest.height;
                final double topPadding = MediaQuery.of(ctx).padding.top;
                final double collapsedHeight = topPadding + kToolbarHeight;
                const double expandedHeight = 140.0;
                final double denominator = expandedHeight - collapsedHeight;
                final double ratio = denominator > 0
                    ? ((expandedHeight - currentHeight) / denominator).clamp(0.0, 1.0)
                    : 0.0;

                // Smoothly interpolate left padding from 16 to 56 to clear the navigation button
                final double leftPadding = 16.0 + (56.0 - 16.0) * ratio;

                return FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.fromLTRB(leftPadding, 0, 16, 14),
                  title: Text(
                    'Component Showcase',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cs.primaryContainer,
                              cs.secondaryContainer,
                            ],
                          ),
                        ),
                      ),
                      // Decorative circles
                      Positioned(
                        right: -30, top: -30,
                        child: Container(
                          width: 150, height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 50, bottom: -20,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.secondary.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Pattern text
                      Positioned(
                        right: 16, top: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '100+',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.primary.withOpacity(0.15),
                                fontSize: 48,
                              ),
                            ),
                            Text(
                              'Components',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: cs.primary.withOpacity(0.3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Stats strip
          SliverToBoxAdapter(
            child: _StatsStrip()
                .animate().fadeIn(duration: 350.ms)
                .slideY(begin: 0.05, duration: 350.ms),
          ),

          // ── Sections
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ..._sections.asMap().entries.map((e) {
                  final i = e.key;
                  final section = e.value;
                  return _SectionCard(section: section)
                      .animate(delay: Duration(milliseconds: 60 * i))
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05, duration: 300.ms);
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    const stats = [
      ('17', 'Pages'),
      ('100+', 'Components'),
      ('10', 'Themes'),
      ('40+', 'Packages'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final isLast = e.key == stats.length - 1;
          final (val, label) = e.value;
          return Expanded(
            child: Container(
              decoration: !isLast
                  ? BoxDecoration(
                      border: Border(
                        right: BorderSide(color: cs.primary.withOpacity(0.2)),
                      ),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    val,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final _ShowcaseSection section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: section.accentColor ?? cs.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  section.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (section.accentColor ?? cs.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${section.items.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: section.accentColor ?? cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: section.items.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final isLast = i == section.items.length - 1;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.vertical(
                          top: i == 0 ? const Radius.circular(AppSpacing.radiusLg) : Radius.zero,
                          bottom: isLast ? const Radius.circular(AppSpacing.radiusLg) : Radius.zero,
                        ),
                        onTap: () => context.push(item.route),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(item.icon, color: item.color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.label,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        if (item.isNew) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: item.color,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'NEW',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (item.description != null)
                                      Text(
                                        item.description!,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Iconsax.arrow_right_3, size: 18, color: cs.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 1, indent: 62, color: cs.outlineVariant),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────
class _ShowcaseSection {
  final String title;
  final List<_ShowcaseItem> items;
  final Color? accentColor;
  const _ShowcaseSection({required this.title, required this.items, this.accentColor});
}

class _ShowcaseItem {
  final String label;
  final String? description;
  final IconData icon;
  final String route;
  final Color color;
  final bool isNew;
  const _ShowcaseItem(this.label, this.icon, this.route, this.color, {this.description, this.isNew = false});
}

const _sections = [
  _ShowcaseSection(
    title: 'Notification Center ✦ Sprint 4',
    accentColor: Color(0xFF7C3AED),
    items: [
      _ShowcaseItem(
        'AppNotificationCenter',
        Iconsax.notification,
        '/showcase/notification-center',
        Color(0xFF7C3AED),
        description: 'Enterprise inbox · 6 card variants · swipe · bulk ops · filter · search · groups · 3-layout responsive · preferences',
        isNew: true,
      ),
    ],
  ),
  _ShowcaseSection(
    title: 'Navigation Framework ✦ Sprint 3',
    accentColor: Color(0xFF0891B2),
    items: [
      _ShowcaseItem(
        'AppNavigationWorkspace',
        Iconsax.category,
        '/showcase/navigation',
        Color(0xFF0891B2),
        description:
            'AWS/Azure-style shell · 72↔280px drawer · tree · permissions · search · recents · favourites',
        isNew: true,
      ),
    ],
  ),
  _ShowcaseSection(
    title: 'Infrastructure & Services ✦ Sprint 2',
    accentColor: Color(0xFF7C3AED),
    items: [
      _ShowcaseItem(
        'All Services & Components',
        Iconsax.ranking,
        '/showcase/services',
        Color(0xFF7C3AED),
        description:
            'Notifications · Feature Flags · Biometric · Enc Storage · Cache · Wizard · Search · Charts',
        isNew: true,
      ),
    ],
  ),
  _ShowcaseSection(
    title: 'Enterprise (New)',
    accentColor: Color(0xFF7C3AED),
    items: [
      _ShowcaseItem('Enterprise Components', Iconsax.element_4, RouteNames.showcaseComponents, Color(0xFF7C3AED),
        description: 'Toasts, banners, gradients, tags, rating, timeline, table',
        isNew: true),
      _ShowcaseItem('Theme Configuration', Iconsax.candle_2, RouteNames.showcaseThemeConfig, Color(0xFF2563EB),
        description: '10 color presets, fonts, radius, density, accessibility',
        isNew: true),
      _ShowcaseItem('UI Kit (Product Cards & More)', Iconsax.colors_square, RouteNames.showcaseUiKit, Color(0xFFEC4899),
        description: 'Product cards, feature cards, promo banners, floating nav',
        isNew: true),
      _ShowcaseItem('Food & Restaurant UI', Iconsax.cup, RouteNames.showcaseFood, Color(0xFFDC2626),
        description: 'Restaurant cards, food wheel, filters, offer banners — Zomato style',
        isNew: true),
      _ShowcaseItem('Advanced Giant-App UX', Iconsax.magicpen, RouteNames.showcaseAdvanced, Color(0xFF7C3AED),
        description: 'Snapping sheets, context preview, popovers, mini-player, media picker, permissions',
        isNew: true),
    ],
  ),
  _ShowcaseSection(
    title: 'Platform Services (New)',
    accentColor: Color(0xFF0891B2),
    items: [
      _ShowcaseItem('App Glass Card + Metric Grid', Iconsax.element_4, RouteNames.showcaseComponents, Color(0xFF0891B2),
        description: 'Multi-variant glass cards, metric grid, footer cards, glow variant',
        isNew: true),
      _ShowcaseItem('App Status Pill', Iconsax.record, RouteNames.showcaseComponents, Color(0xFF16A34A),
        description: 'Semantic status pills: success, error, warning, info, pending',
        isNew: true),
      _ShowcaseItem('Analytics Service', Iconsax.presention_chart, RouteNames.showcaseComponents, Color(0xFF9333EA),
        description: 'Firebase Analytics abstraction — screen tracking, events, user properties',
        isNew: true),
      _ShowcaseItem('Device Info + Lifecycle', Iconsax.monitor_mobbile, RouteNames.showcaseComponents, Color(0xFFD97706),
        description: 'Device ID, version, OS info, app lifecycle observer',
        isNew: true),
    ],
  ),
  _ShowcaseSection(
    title: 'UI Components',
    accentColor: Color(0xFF2563EB),
    items: [
      _ShowcaseItem('Buttons', Iconsax.link, RouteNames.showcaseButtons, Color(0xFF2563EB),
        description: 'Filled, outlined, text, icon, loading, gradient'),
      _ShowcaseItem('Cards', Iconsax.card, RouteNames.showcaseCards, Color(0xFF7C3AED),
        description: 'Elevated, outlined, tinted, interactive'),
      _ShowcaseItem('Form Inputs', Iconsax.import, RouteNames.showcaseInputs, Color(0xFF16A34A),
        description: 'Text, date, select, OTP, search'),
      _ShowcaseItem('Typography', Iconsax.document_text, RouteNames.showcaseTypography, Color(0xFF92400E),
        description: 'Display, headline, body, label scales'),
    ],
  ),
  _ShowcaseSection(
    title: 'Overlays & Feedback',
    accentColor: Color(0xFF0891B2),
    items: [
      _ShowcaseItem('Dialogs', Iconsax.export, RouteNames.showcaseDialogs, Color(0xFF0891B2),
        description: 'Alert, confirm, bottom, fullscreen'),
      _ShowcaseItem('Bottom Sheets', Iconsax.layer, RouteNames.showcaseSheets, Color(0xFFD97706),
        description: 'Modal, scrollable, persistent, snap'),
      _ShowcaseItem('Loaders & Shimmer', Iconsax.timer, RouteNames.showcaseLoaders, Color(0xFF64748B),
        description: 'Progress, shimmer, skeleton, refresh'),
      _ShowcaseItem('State Screens', Iconsax.info_circle, RouteNames.showcaseStates, Color(0xFF7C3AED),
        description: 'Empty, error, loading, success states'),
    ],
  ),
  _ShowcaseSection(
    title: 'Media & Data',
    accentColor: Color(0xFFDC2626),
    items: [
      _ShowcaseItem('Images & Assets', Iconsax.image, RouteNames.showcaseImages, Color(0xFF4F46E5),
        description: 'Gallery, hero, cached, video, PDF viewer'),
      _ShowcaseItem('PDF Viewer', Iconsax.document_text, RouteNames.showcasePdf, Color(0xFFDC2626),
        description: 'Full-featured PDF rendering'),
      _ShowcaseItem('Charts & Analytics', Iconsax.chart, RouteNames.showcaseCharts, Color(0xFF0891B2),
        description: 'Line, bar, pie, radar charts'),
      _ShowcaseItem('Animations', Iconsax.magicpen, RouteNames.showcaseAnimations, Color(0xFFEC4899),
        description: 'Page transitions, hero, stagger'),
    ],
  ),
  _ShowcaseSection(
    title: 'System & DevTools',
    accentColor: Color(0xFF65A30D),
    items: [
      _ShowcaseItem('Theme System', Iconsax.colorfilter, RouteNames.showcaseTheme, Color(0xFFDC2626),
        description: 'Colors, typography, spacing tokens'),
      _ShowcaseItem('Network & API', Iconsax.wifi, RouteNames.showcaseNetwork, Color(0xFF65A30D),
        description: 'Dio, interceptors, offline detection'),
      _ShowcaseItem('Utilities', Iconsax.designtools, RouteNames.showcaseUtils, Color(0xFFD97706),
        description: 'Formatters, validators, extensions'),
    ],
  ),
];
