// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:enterprise_kit/core/router/route_names.dart';
import 'package:enterprise_kit/core/theme/theme_config.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/banners/app_promo_banner.dart';
import 'package:enterprise_kit/shared/widgets/cards/app_product_card.dart';
import 'package:enterprise_kit/shared/widgets/cards/app_restaurant_card.dart';
import 'package:enterprise_kit/shared/widgets/food/app_food_widgets.dart';
import 'package:enterprise_kit/shared/widgets/navigation/app_bottom_nav.dart';

// ─── Home Page ────────────────────────────────────────────────────────────────
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _navIndex = 0;
  final _scrollCtrl = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final s = _scrollCtrl.offset > 20;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // ── Main scroll content
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ── Hero AppBar
              SliverAppBar(
                expandedHeight: 0,
                pinned: true,
                floating: true,
                snap: true,
                elevation: _scrolled ? 1 : 0,
                scrolledUnderElevation: 1,
                backgroundColor: _scrolled
                    ? cs.surface
                    : Colors.transparent,
                surfaceTintColor: Colors.transparent,
                systemOverlayStyle: isDark
                    ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
                    : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
                flexibleSpace: _TopBar(scrolled: _scrolled),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  /*   // ── Location header
                    AppLocationHeader(
                      city: 'Bangalore',
                      area: 'Enterprise Kit',
                      subtitle: 'Flutter • Production-ready',
                      onTap: () {},
                      trailing: IconButton(
                        icon: Badge(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          smallSize: 7,
                          child: Icon(Iconsax.notification,
                              color: Theme.of(context).colorScheme.onSurface, size: 22),
                        ),
                        onPressed: () {},
                      ),
                    ).animate().fadeIn(duration: 300.ms),
 */
                    // ── Search
                    AppTopSearchBar(
                      hint: 'Search components, patterns...',
                      location: '100+ parts',
                      onTap: () {},
                    ).animate().fadeIn(delay: 60.ms, duration: 350.ms),

                    const SizedBox(height: 8),

                    // ── Filter bar
                    AppFilterBar(
                      filters: const [
                        AppFilterChip(label: 'All', leadingIcon: Iconsax.grid_1),
                        AppFilterChip(label: 'New', leadingIcon: Iconsax.flash),
                        AppFilterChip(label: 'Cards & Lists'),
                        AppFilterChip(label: 'Overlays'),
                        AppFilterChip(label: 'Forms'),
                        AppFilterChip(label: 'Media'),
                      ],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      onSelected: (_) {},
                    ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

                    const SizedBox(height: 4),

                    // ── Promo banners
                    AppPromoBanner(
                      height: 155,
                      items: _promoBanners,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: 10),

                    // ── Trust strip
                    appInfoStripDefault()
                        .animate().fadeIn(delay: 150.ms, duration: 350.ms),

                    const SizedBox(height: 4),

                    // ── Food Category Wheel
                    AppFoodCategoryWheel(
                      title: "Browse Components",
                      categories: _componentCategories,
                    ).animate().fadeIn(delay: 170.ms, duration: 350.ms),

                    // ── Categories
                    const AppSectionHeader(
                      title: 'Quick Navigation',
                      subtitle: 'All component sections',
                    ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

                    _CategoryGrid()
                        .animate().fadeIn(delay: 250.ms, duration: 350.ms),

                    // ── Restaurant-style Featured Cards
                    AppSectionHeader(
                      title: 'Featured Packages',
                      subtitle: 'Most-used enterprise components',
                      actionLabel: 'Food UI →',
                      onAction: () => context.push(RouteNames.showcaseFood),
                    ).animate().fadeIn(delay: 270.ms, duration: 350.ms),

                    _RestaurantStyleStrip()
                        .animate().fadeIn(delay: 290.ms, duration: 350.ms),

                    // ── Stats section
                    AppSectionHeader(
                      title: 'Live Dashboard',
                      subtitle: 'Real-time business metrics',
                      actionLabel: 'Full Report',
                      onAction: () => context.push(RouteNames.showcase),
                    ).animate().fadeIn(delay: 280.ms, duration: 350.ms),

                    _StatsSection()
                        .animate().fadeIn(delay: 300.ms, duration: 350.ms),

                    // ── Featured cards
                    AppSectionHeader(
                      title: 'Featured Components',
                      subtitle: 'Handpicked for you',
                      actionLabel: 'See All',
                      onAction: () => context.push(RouteNames.showcase),
                    ).animate().fadeIn(delay: 330.ms, duration: 350.ms),

                    _FeaturedScroll()
                        .animate().fadeIn(delay: 360.ms, duration: 350.ms),

                    // ── Showcase sections grid
                    AppSectionHeader(
                      title: 'Component Library',
                      subtitle: '${_showcaseSections.length} sections, 100+ components',
                    ).animate().fadeIn(delay: 380.ms, duration: 350.ms),

                    _ShowcaseGrid()
                        .animate().fadeIn(delay: 400.ms, duration: 350.ms),

                    // ── Recent / Quick access
                    const AppSectionHeader(
                      title: 'Quick Actions',
                    ).animate().fadeIn(delay: 430.ms, duration: 350.ms),

                    _QuickActionsRow()
                        .animate().fadeIn(delay: 450.ms, duration: 350.ms),

                    // Bottom spacing for floating nav
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),

          // ── Floating bottom nav
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AppFloatingBottomNav(
              currentIndex: _navIndex,
              onIndexChanged: (i) {
                setState(() => _navIndex = i);
                if (i == 1) context.push(RouteNames.showcase);
              },
              items: const [
                AppBottomNavItem(icon: Iconsax.home, activeIcon: Iconsax.home, label: 'Home'),
                AppBottomNavItem(icon: Iconsax.grid_1, activeIcon: Iconsax.grid_1, label: 'Showcase'),
                AppBottomNavItem(icon: Iconsax.candle_2, activeIcon: Iconsax.candle_2, label: 'Theme'),
                AppBottomNavItem(icon: Iconsax.profile, activeIcon: Iconsax.profile, label: 'Profile', hasDot: true),
              ],
            ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 300.ms, curve: Curves.easeOutCubic)
              .fadeIn(delay: 300.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final bool scrolled;
  const _TopBar({required this.scrolled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final themeConfig = ref.watch(themeConfigProvider);
    final notifier = ref.read(themeConfigProvider.notifier);

    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 6, 12, 6),
      decoration: BoxDecoration(
        color: scrolled ? cs.surface : Colors.transparent,
        border: scrolled
            ? Border(bottom: BorderSide(color: cs.outlineVariant))
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          // App icon + greeting
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.secondary],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.layer, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enterprise Kit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Flutter • Production-ready',
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Dark mode toggle
          _ThemeToggle(isDark: themeConfig.mode == ThemeMode.dark, onToggle: () {
            notifier.setMode(
              themeConfig.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
            );
          }),
          // Notifications
          IconButton(
            icon: Badge(
              backgroundColor: cs.error,
              smallSize: 8,
              child: Icon(Iconsax.notification, color: cs.onSurface),
            ),
            onPressed: () {},
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: const EdgeInsets.all(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const _ThemeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? cs.primary : cs.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: isDark ? 24 : 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : cs.onSurface.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Iconsax.moon : Iconsax.sun_1,
                  size: 13,
                  color: isDark ? cs.primary : cs.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Restaurant Style Strip ───────────────────────────────────────────────────
class _RestaurantStyleStrip extends StatelessWidget {
  static final _items = [
    const _PkgItem('Overlay System', 'Toast • Banner • Dialog', 4.9, '100% safe', RouteNames.showcaseComponents,
        [Color(0xFF1D4ED8), Color(0xFF7C3AED)]),
    const _PkgItem('Theme Engine', 'Dynamic colors & dark mode', 4.8, 'Light/Dark', RouteNames.showcaseThemeConfig,
        [Color(0xFF7C3AED), Color(0xFFEC4899)]),
    const _PkgItem('Data Components', 'Table • Chart • Paginator', 4.7, 'Sort & filter', RouteNames.showcaseComponents,
        [Color(0xFF0891B2), Color(0xFF16A34A)]),
    const _PkgItem('Media Viewer', 'Images • PDF • Hero', 4.6, 'Cached & smooth', RouteNames.showcaseImages,
        [Color(0xFFD97706), Color(0xFFDC2626)]),
    const _PkgItem('Forms & Inputs', 'Text • Date • OTP • Select', 4.8, 'Validated', RouteNames.showcaseInputs,
        [Color(0xFF16A34A), Color(0xFF0891B2)]),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = _items[i];
          return GestureDetector(
            onTap: () => context.push(item.route),
            child: Container(
              width: 185,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Gradient strip at top
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: item.colors),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Iconsax.star, size: 9, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    item.rating.toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.sub,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Iconsax.verify, size: 12, color: item.colors.first),
                            const SizedBox(width: 4),
                            Text(
                              item.badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: item.colors.first,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate(delay: Duration(milliseconds: 50 * i))
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.04, duration: 300.ms),
          );
        },
      ),
    );
  }
}

class _PkgItem {
  final String name, sub, badge, route;
  final double rating;
  final List<Color> colors;
  const _PkgItem(this.name, this.sub, this.rating, this.badge, this.route, this.colors);
}

// ─── Category Grid ────────────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  static const _cats = [
    _Cat('Buttons', Iconsax.link, Color(0xFF2563EB), RouteNames.showcaseButtons),
    _Cat('Cards', Iconsax.card, Color(0xFF7C3AED), RouteNames.showcaseCards),
    _Cat('Dialogs', Iconsax.export, Color(0xFF0891B2), RouteNames.showcaseDialogs),
    _Cat('Inputs', Iconsax.document_text, Color(0xFF16A34A), RouteNames.showcaseInputs),
    _Cat('Charts', Iconsax.chart, Color(0xFFD97706), RouteNames.showcaseCharts),
    _Cat('Themes', Iconsax.colorfilter, Color(0xFFDC2626), RouteNames.showcaseThemeConfig),
    _Cat('Media', Iconsax.image, Color(0xFF7C3AED), RouteNames.showcaseImages),
    _Cat('Loaders', Iconsax.timer, Color(0xFF0284C7), RouteNames.showcaseLoaders),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
        children: _cats.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return _CategoryCard(cat: c)
              .animate(delay: Duration(milliseconds: 40 * i))
              .scale(begin: const Offset(0.7, 0.7), duration: 400.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms);
        }).toList(),
      ),
    );
  }
}

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _Cat(this.label, this.icon, this.color, this.route);
}

class _CategoryCard extends StatelessWidget {
  final _Cat cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push(cat.route),
      child: Container(
        decoration: BoxDecoration(
          color: cat.color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: cat.color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              cat.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Section ────────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
        children: [
          const AppStatCard(
            label: 'Components',
            value: '100+',
            subValue: 'Production ready',
            trend: '+12 new',
            trendUp: true,
            icon: Iconsax.element_4,
            color: Color(0xFF2563EB),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
          const AppStatCard(
            label: 'Theme Presets',
            value: '10',
            subValue: 'Colors + custom',
            trend: 'All new',
            trendUp: true,
            icon: Iconsax.colorfilter,
            color: Color(0xFF7C3AED),
          ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
          const AppStatCard(
            label: 'Showcase Pages',
            value: '17',
            subValue: 'With live demos',
            trend: '+3 new',
            trendUp: true,
            icon: Iconsax.gallery,
            color: Color(0xFF0891B2),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05),
          const AppStatCard(
            label: 'Packages',
            value: '40+',
            subValue: 'Pre-integrated',
            trend: 'Stable',
            trendUp: true,
            icon: Iconsax.box,
            color: Color(0xFF16A34A),
          ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
        ],
      ),
    );
  }
}

// ─── Featured Scroll ──────────────────────────────────────────────────────────
class _FeaturedScroll extends StatelessWidget {
  static final _items = [
    const _FeaturedItem(
      'Toast & Banners',
      'Global notification system',
      [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
      RouteNames.showcaseComponents,
      'Overlay • Alert • Feedback',
    ),
    const _FeaturedItem(
      'Theme Config',
      '10 presets, fonts, radius',
      [Color(0xFF7C3AED), Color(0xFFEC4899)],
      RouteNames.showcaseThemeConfig,
      'Light • Dark • Custom',
    ),
    const _FeaturedItem(
      'Data Table',
      'Sort, filter, paginate',
      [Color(0xFF0891B2), Color(0xFF2563EB)],
      RouteNames.showcaseComponents,
      'Columns • Selection • Sort',
    ),
    const _FeaturedItem(
      'Asset Viewer',
      'Images, video, files',
      [Color(0xFFD97706), Color(0xFFDC2626)],
      RouteNames.showcaseImages,
      'Gallery • Hero • Cache',
    ),
    const _FeaturedItem(
      'Pagination',
      'Any list or grid',
      [Color(0xFF16A34A), Color(0xFF0891B2)],
      RouteNames.showcaseComponents,
      'Infinite • Refresh • Skeleton',
    ),
    const _FeaturedItem(
      'UI Kit',
      'Product cards, promo banners',
      [Color(0xFFEC4899), Color(0xFFD97706)],
      RouteNames.showcaseUiKit,
      'Cards • Nav • Banners',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = _items[i];
          return _FeaturedCard(item: item)
              .animate(delay: Duration(milliseconds: 60 * i))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05, duration: 300.ms);
        },
      ),
    );
  }
}

class _FeaturedItem {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final String route;
  final String tags;
  const _FeaturedItem(this.title, this.subtitle, this.colors, this.route, this.tags);
}

class _FeaturedCard extends StatelessWidget {
  final _FeaturedItem item;
  const _FeaturedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Hero(
        tag: 'featured_${item.title}',
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item.colors,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: item.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.element_4, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  item.tags,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Showcase Grid ────────────────────────────────────────────────────────────
class _ShowcaseGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
        children: _showcaseSections.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return _ShowcaseTile(entry: s)
              .animate(delay: Duration(milliseconds: 35 * i))
              .scale(begin: const Offset(0.85, 0.85), duration: 350.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 250.ms);
        }).toList(),
      ),
    );
  }
}

class _ShowcaseEntry {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  final String? badge;
  const _ShowcaseEntry(this.label, this.icon, this.route, this.color, {this.badge});
}

const _showcaseSections = [
  _ShowcaseEntry('Buttons', Iconsax.device_message, RouteNames.showcaseButtons, Color(0xFF2563EB)),
  _ShowcaseEntry('Cards', Iconsax.card, RouteNames.showcaseCards, Color(0xFF7C3AED)),
  _ShowcaseEntry('Dialogs', Iconsax.menu, RouteNames.showcaseDialogs, Color(0xFF0891B2)),
  _ShowcaseEntry('Sheets', Iconsax.layer, RouteNames.showcaseSheets, Color(0xFFD97706)),
  _ShowcaseEntry('Inputs', Iconsax.import, RouteNames.showcaseInputs, Color(0xFF16A34A)),
  _ShowcaseEntry('Theme', Iconsax.colorfilter, RouteNames.showcaseTheme, Color(0xFFDC2626)),
  _ShowcaseEntry('Images', Iconsax.image, RouteNames.showcaseImages, Color(0xFF4F46E5)),
  _ShowcaseEntry('Typography', Iconsax.document_text, RouteNames.showcaseTypography, Color(0xFF92400E)),
  _ShowcaseEntry('Charts', Iconsax.chart, RouteNames.showcaseCharts, Color(0xFF0891B2)),
  _ShowcaseEntry('Network', Iconsax.wifi, RouteNames.showcaseNetwork, Color(0xFF65A30D)),
  _ShowcaseEntry('Utilities', Iconsax.designtools, RouteNames.showcaseUtils, Color(0xFFD97706)),
  _ShowcaseEntry('Animate', Iconsax.magicpen, RouteNames.showcaseAnimations, Color(0xFFEC4899)),
  _ShowcaseEntry('Loaders', Iconsax.timer, RouteNames.showcaseLoaders, Color(0xFF64748B)),
  _ShowcaseEntry('PDF', Iconsax.document_text, RouteNames.showcasePdf, Color(0xFFDC2626)),
  _ShowcaseEntry('States', Iconsax.layer, RouteNames.showcaseStates, Color(0xFF7C3AED)),
  _ShowcaseEntry('Components', Iconsax.element_4, RouteNames.showcaseComponents, Color(0xFF0891B2), badge: 'NEW'),
  _ShowcaseEntry('Config', Iconsax.candle_2, RouteNames.showcaseThemeConfig, Color(0xFF7C3AED), badge: 'NEW'),
  _ShowcaseEntry('UI Kit', Iconsax.colors_square, RouteNames.showcaseUiKit, Color(0xFFEC4899), badge: 'NEW'),
  _ShowcaseEntry('Food UI', Iconsax.cup, RouteNames.showcaseFood, Color(0xFFDC2626), badge: 'NEW'),
];

class _ShowcaseTile extends StatelessWidget {
  final _ShowcaseEntry entry;
  const _ShowcaseTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push(entry.route),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: entry.color.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: entry.color.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(entry.icon, color: entry.color, size: 22),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    entry.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      fontSize: 10.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (entry.badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: entry.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final actions = [
      _QuickAction('Toast\nDemo', Iconsax.notification, const Color(0xFF2563EB), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enterprise Kit is ready!'),
            backgroundColor: cs.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }),
      _QuickAction('Theme\nConfig', Iconsax.colorfilter, const Color(0xFF7C3AED),
          () => context.push(RouteNames.showcaseThemeConfig)),
      _QuickAction('Components\nShowcase', Iconsax.element_4, const Color(0xFF0891B2),
          () => context.push(RouteNames.showcaseComponents)),
      _QuickAction('All\nShowcase', Iconsax.grid_1, const Color(0xFF16A34A),
          () => context.push(RouteNames.showcase)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          final isLast = i == actions.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: GestureDetector(
                onTap: a.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: a.color.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.icon, size: 22, color: a.color),
                      const SizedBox(height: 5),
                      Text(
                        a.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          fontSize: 9.5,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 50 * i))
               .scale(begin: const Offset(0.85, 0.85), duration: 350.ms, curve: Curves.easeOutBack)
               .fadeIn(duration: 250.ms),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}

// ─── Component Categories (used in AppFoodCategoryWheel) ─────────────────────
final _componentCategories = [
  const AppFoodCategory(label: 'Buttons', icon: Iconsax.link, color: Color(0xFF2563EB)),
  const AppFoodCategory(label: 'Cards', icon: Iconsax.card, color: Color(0xFF7C3AED)),
  const AppFoodCategory(label: 'Dialogs', icon: Iconsax.export, color: Color(0xFF0891B2)),
  const AppFoodCategory(label: 'Inputs', icon: Iconsax.document_text, color: Color(0xFF16A34A)),
  const AppFoodCategory(label: 'Charts', icon: Iconsax.chart, color: Color(0xFFD97706)),
  const AppFoodCategory(label: 'Themes', icon: Iconsax.colorfilter, color: Color(0xFFDC2626)),
  const AppFoodCategory(label: 'Media', icon: Iconsax.image, color: Color(0xFF4F46E5)),
  const AppFoodCategory(label: 'Overlays', icon: Iconsax.layer, color: Color(0xFFEC4899)),
  const AppFoodCategory(label: 'Loaders', icon: Iconsax.timer, color: Color(0xFF64748B)),
  const AppFoodCategory(label: 'Food UI', icon: Iconsax.cup, color: Color(0xFFDC2626)),
];

// ─── Promo Banner Data ────────────────────────────────────────────────────────
final _promoBanners = [
  AppPromoBannerItem(
    title: 'Enterprise-Grade\nFlutter UI Kit',
    subtitle: 'PRODUCTION READY',
    ctaLabel: 'Explore →',
    gradientColors: [const Color(0xFF1D4ED8), const Color(0xFF7C3AED)],
    onTap: () {},
  ),
  AppPromoBannerItem(
    title: '10 Theme Presets\n+ Custom Colors',
    subtitle: 'FULL THEMING',
    ctaLabel: 'Try It →',
    gradientColors: [const Color(0xFF7C3AED), const Color(0xFFEC4899)],
    onTap: () {},
  ),
  AppPromoBannerItem(
    title: 'Smooth Animations\n& Hero Transitions',
    subtitle: 'FLUTTER ANIMATE',
    ctaLabel: 'See Demo →',
    gradientColors: [const Color(0xFF0891B2), const Color(0xFF2563EB)],
    onTap: () {},
  ),
  AppPromoBannerItem(
    title: 'Toast, Banners,\nDialogs & More',
    subtitle: '100+ COMPONENTS',
    ctaLabel: 'View All →',
    gradientColors: [const Color(0xFF16A34A), const Color(0xFF0891B2)],
    onTap: () {},
  ),
];
