// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/permissions/app_permission_manager.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/sheets/app_snapping_sheet.dart';
import 'package:enterprise_kit/shared/widgets/overlays/app_context_preview.dart';
import 'package:enterprise_kit/shared/widgets/overlays/app_popover.dart';
import 'package:enterprise_kit/shared/widgets/player/app_mini_player.dart';
import 'package:enterprise_kit/shared/widgets/bars/app_app_bar.dart';
import 'package:enterprise_kit/shared/widgets/pickers/app_media_picker.dart';

// ─── Advanced Showcase Page ───────────────────────────────────────────────────

class AdvancedShowcasePage extends StatefulWidget {
  const AdvancedShowcasePage({super.key});

  @override
  State<AdvancedShowcasePage> createState() => _AdvancedShowcasePageState();
}

class _AdvancedShowcasePageState extends State<AdvancedShowcasePage>
    with TickerProviderStateMixin {
  late TabController _tab;
  late ScrollController _scrollCtrl;
  bool _isCollapsed = false;

  static const _tabs = [
    (icon: Iconsax.layer, label: 'Sheets'),
    (icon: Iconsax.scan, label: 'Previews'),
    (icon: Iconsax.export, label: 'Popovers'),
    (icon: Iconsax.musicnote, label: 'Player'),
    (icon: Iconsax.image, label: 'Media'),
    (icon: Iconsax.security, label: 'Permissions'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _scrollCtrl = ScrollController()
      ..addListener(() {
        final collapsed = _scrollCtrl.offset > 60;
        if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
      });
  }

  @override
  void dispose() {
    _tab.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 1,
            // Title visible when collapsed — adapts to scroll state
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isCollapsed ? 1.0 : 0.0,
              child: Text(
                'Advanced Components',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              // titlePadding: null disables the built-in title; we render our own
              titlePadding: EdgeInsets.zero,
              background: _HeaderBackground(isCollapsed: _isCollapsed),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: ColoredBox(
                color: cs.surface,
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: cs.outlineVariant,
                  indicatorColor: cs.primary,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: _tabs
                      .map((t) => Tab(
                            height: 46,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(t.icon, size: 14),
                                const SizedBox(width: 6),
                                Text(t.label),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _SheetsTab(),
            _ContextPreviewTab(),
            _PopoverTab(),
            _MiniPlayerTab(),
            _MediaPickerTab(),
            const _PermissionsTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Header Background ────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final bool isCollapsed;
  const _HeaderBackground({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isCollapsed ? 0.0 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF7C3AED), cs.primary],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 60, bottom: 30,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Title text
            Positioned(
              left: 16, bottom: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Advanced Components',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Giant-app UX patterns · Uber · Spotify · Instagram',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Snapping Sheets ───────────────────────────────────────────────────

class _SheetsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          'AppSnappingSheet',
          'Uber / Airbnb multi-snap elastic sheets',
          Iconsax.layer,
          Color(0xFF1B1B2F),
        ),
        const SizedBox(height: 12),

        _DemoCard(
          label: 'Uber-style Map Sheet',
          description: 'Multi-snap (35% → 60% → 92%) with scrim + rubber-band physics',
          icon: Iconsax.routing,
          color: const Color(0xFF1B1B2F),
          onTap: () => _showMapSheet(context),
        ),
        const SizedBox(height: 10),
        _DemoCard(
          label: 'Filter Panel Sheet',
          description: 'Chips + range slider — AppFilterSheet preset',
          icon: Iconsax.candle_2,
          color: const Color(0xFF2563EB),
          onTap: () => AppFilterSheet.show(
            context: context,
            filterTags: ['Veg', 'Non-Veg', 'Fast Food', 'Desserts', 'Healthy', 'Trending'],
            minValue: 0,
            maxValue: 5,
            initialMin: 3,
            initialMax: 5,
            rangeLabel: 'Rating',
            rangeFormatter: (v) => v.toStringAsFixed(1),
          ),
        ),
        const SizedBox(height: 10),
        _DemoCard(
          label: 'Options Sheet',
          description: 'iOS-style action list — AppOptionSheet preset',
          icon: Iconsax.menu,
          color: const Color(0xFF16A34A),
          onTap: () => AppOptionSheet.show(
            context: context,
            title: 'Share via',
            subtitle: 'Choose how to share this item',
            options: [
              const AppOptionItem(icon: Iconsax.link, label: 'Copy Link'),
              const AppOptionItem(icon: Iconsax.send_2, label: 'Share Sheet'),
              const AppOptionItem(icon: Iconsax.archive_1, label: 'Save'),
              const AppOptionItem(
                  icon: Iconsax.danger, label: 'Report', isDestructive: true),
            ],
          ),
        ),
      ].animate(interval: 80.ms).fadeIn(duration: 250.ms).slideY(begin: 0.04),
    );
  }

  void _showMapSheet(BuildContext context) {
    AppSnappingSheet.show(
      context: context,
      background: _FakeMapBackground(),
      snapConfig: const AppSnapConfig(
        snapSizes: [0.35, 0.6, 0.92],
        initialSnap: 0,
        minSize: 0.35,
        maxSize: 0.92,
      ),
      header: AppSheetHeader(
        title: '3 restaurants nearby',
        subtitle: 'Sorted by distance',
        trailing: TextButton.icon(
          icon: const Icon(Iconsax.candle_2, size: 14),
          label: const Text('Filters'),
          onPressed: () {},
        ),
      ),
      contentBuilder: (ctx, scroll) => ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (_, i) => _MapResultTile(index: i),
      ),
    );
  }
}

class _FakeMapBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F0E8),
      child: Stack(
        children: [
          Positioned.fill(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
              itemCount: 64,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: i % 5 == 0
                      ? Colors.green.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          ...List.generate(
              4,
              (i) => Positioned(
                    top: 50.0 + i * 80,
                    left: 0,
                    right: 0,
                    height: 8,
                    child: Container(color: Colors.white.withOpacity(0.7)),
                  )),
          ...List.generate(
              3,
              (i) => Positioned(
                    left: 60.0 + i * 90,
                    top: 0,
                    bottom: 0,
                    width: 8,
                    child: Container(color: Colors.white.withOpacity(0.7)),
                  )),
          const Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Iconsax.location, color: Colors.red, size: 40),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapResultTile extends StatelessWidget {
  final int index;
  const _MapResultTile({required this.index});

  static const _names = [
    'Burger Palace', 'Spice Garden', 'The Pasta Place',
    'Sushi Wave', 'Green Bowl', 'Taco Town'
  ];
  static const _distances = ['0.4 km', '0.8 km', '1.2 km', '1.5 km', '1.9 km', '2.3 km'];
  static const _times = ['12 min', '18 min', '22 min', '28 min', '35 min', '40 min'];
  static const _ratings = [4.7, 4.3, 4.5, 4.8, 4.1, 4.6];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final i = index % _names.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 52,
                height: 52,
                color: const Color(0xFFFF6B35).withOpacity(0.15),
                child:
                    const Icon(Iconsax.cup, color: Color(0xFFFF6B35), size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_names[i],
                      style:
                          const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Iconsax.star, color: Colors.amber, size: 13),
                    const SizedBox(width: 3),
                    Text('${_ratings[i]}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant)),
                    Text('  ·  ${_distances[i]}  ·  ${_times[i]}',
                        style:
                            TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ]),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: cs.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Context Previews ──────────────────────────────────────────────────

class _ContextPreviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          'AppContextPreview',
          'Instagram / Telegram 3D-touch haptic long-press preview',
          Iconsax.scan,
          Color(0xFF833AB4),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.35),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: cs.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Iconsax.scan, size: 14, color: cs.primary),
              const SizedBox(width: 8),
              Text('Long-press any card below',
                  style: TextStyle(
                      color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(4, (i) {
          const titles = ['Margherita Pizza', 'Chicken Tikka', 'Sushi Platter', 'Avocado Toast'];
          const prices = ['₹299', '₹449', '₹599', '₹199'];
          const descriptions = [
            'Classic Italian pizza with fresh mozzarella and basil',
            'Grilled chicken in aromatic spices, served with mint chutney',
            'Fresh sashimi and rolls, artfully plated with wasabi',
            'Toasted sourdough with smashed avocado and poached egg',
          ];
          const colors = [
            Color(0xFFFF6B35), Color(0xFFFF9800), Color(0xFF2196F3), Color(0xFF4CAF50)
          ];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppContextPreview(
              previewHeight: 260,
              actions: [
                AppQuickAction(
                    icon: Iconsax.shopping_cart,
                    label: 'Add to Cart',
                    onTap: () {}),
                AppQuickAction(
                    icon: Iconsax.heart,
                    label: 'Save',
                    onTap: () {}),
                AppQuickAction(
                    icon: Iconsax.send_2, label: 'Share', onTap: () {}),
                AppQuickAction(
                    icon: Iconsax.danger,
                    label: 'Report',
                    isDestructive: true,
                    onTap: () {}),
              ],
              preview: _FoodPreviewCard(
                title: titles[i],
                description: descriptions[i],
                price: prices[i],
                color: colors[i],
              ),
              child: _FoodListItem(
                  title: titles[i], price: prices[i], color: colors[i]),
            ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 250.ms),
          );
        }),
      ],
    );
  }
}

class _FoodPreviewCard extends StatelessWidget {
  final String title, description, price;
  final Color color;
  const _FoodPreviewCard(
      {required this.title,
      required this.description,
      required this.price,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 160,
          color: color.withOpacity(0.2),
          child: Center(child: Icon(Iconsax.cup, color: color, size: 64)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 6),
              Text(description,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(price,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w900, fontSize: 20)),
                  FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    child: const Text('Add', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodListItem extends StatelessWidget {
  final String title, price;
  final Color color;
  const _FoodListItem({required this.title, required this.price, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Iconsax.coffee, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(price,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          Icon(Iconsax.add_circle, color: color),
        ],
      ),
    );
  }
}

// ─── Tab 3: Popovers + AppBar ─────────────────────────────────────────────────

class _PopoverTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          'AppPopover',
          'Anchor-positioned floating cards with auto-flip',
          Iconsax.export,
          Color(0xFF0891B2),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppPopoverAnchor(
              position: AppPopoverPosition.bottom,
              popover: _InfoPopoverContent(),
              child: FilledButton.icon(
                icon: const Icon(Iconsax.info_circle, size: 16),
                label: const Text('Info Popover'),
                onPressed: null,
              ),
            ),
            AppMenuPopover(
              items: [
                AppPopoverMenuItem(
                    icon: Iconsax.edit, label: 'Edit', onTap: () {}),
                AppPopoverMenuItem(
                    icon: Iconsax.copy, label: 'Duplicate', onTap: () {}),
                AppPopoverMenuItem(
                    icon: Iconsax.send_2, label: 'Share', onTap: () {}),
                AppPopoverMenuItem(
                    icon: Iconsax.trash,
                    label: 'Delete',
                    isDestructive: true,
                    onTap: () {}),
              ],
              child: OutlinedButton.icon(
                icon: const Icon(Iconsax.more, size: 16),
                label: const Text('Menu Popover'),
                onPressed: null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),
        const _SectionHeader(
          'AppAppBar',
          'Glassmorphic adaptive bar — transparent → blur on scroll',
          Iconsax.monitor,
          Color(0xFF7C3AED),
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: const _AppBarPreview(),
        ),

        const SizedBox(height: 28),
        const _SectionHeader(
          'AppBarScrollBehavior',
          'Four scroll-linked behavior modes',
          Iconsax.element_equal,
          Color(0xFF16A34A),
        ),
        const SizedBox(height: 12),
        ...AppBarScrollBehavior.values.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DemoCard(
                label: b.name.replaceAllMapped(
                    RegExp(r'([A-Z])'), (m) => ' ${m[0]}').trim().toUpperCase(),
                description: _behaviorDesc(b),
                icon: _behaviorIcon(b),
                color: cs.primary,
                onTap: () {},
              ),
            )),
      ].animate(interval: 60.ms).fadeIn(duration: 250.ms).slideY(begin: 0.04),
    );
  }

  String _behaviorDesc(AppBarScrollBehavior b) => switch (b) {
        AppBarScrollBehavior.transparent => 'Always transparent — overlays content',
        AppBarScrollBehavior.glassmorphic => 'Blur ramps 0→16 over 60px scroll',
        AppBarScrollBehavior.solid => 'Opaque from first scroll pixel',
        AppBarScrollBehavior.hideOnScrollDown =>
          'Slides out on scroll-down, returns on scroll-up',
      };

  IconData _behaviorIcon(AppBarScrollBehavior b) => switch (b) {
        AppBarScrollBehavior.transparent => Iconsax.element_4,
        AppBarScrollBehavior.glassmorphic => Iconsax.element_4,
        AppBarScrollBehavior.solid => Iconsax.element_3,
        AppBarScrollBehavior.hideOnScrollDown => Iconsax.arrow_swap_horizontal,
      };
}

class _InfoPopoverContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(children: [
          Icon(Iconsax.star, color: Colors.amber, size: 16),
          SizedBox(width: 6),
          Text('4.8 Rating',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        Text('Based on 1,240 reviews',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 10),
        const _RatingRow('Food', 4.9),
        const _RatingRow('Service', 4.7),
        const _RatingRow('Packaging', 4.8),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final double rating;
  const _RatingRow(this.label, this.rating);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(
            width: 64, child: Text(label, style: const TextStyle(fontSize: 11))),
        Expanded(
          child: LinearProgressIndicator(
            value: rating / 5,
            backgroundColor: cs.outlineVariant,
            valueColor: const AlwaysStoppedAnimation(Colors.amber),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(rating.toString(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _AppBarPreview extends StatefulWidget {
  const _AppBarPreview();
  @override
  State<_AppBarPreview> createState() => _AppBarPreviewState();
}

class _AppBarPreviewState extends State<_AppBarPreview> {
  final _sc = ScrollController();
  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListView.builder(
        controller: _sc,
        itemCount: 20,
        itemBuilder: (_, i) => ListTile(
          title: Text('Item $i'),
          subtitle: const Text('Scroll to see glassmorphic effect'),
        ),
      ),
      AppAppBar(
        title: 'Glassmorphic Bar',
        behavior: AppBarScrollBehavior.glassmorphic,
        scrollController: _sc,
        actions: [
          const IconButton(
              icon: Icon(Iconsax.search_normal), onPressed: null),
        ],
      ),
    ]);
  }
}

// ─── Tab 4: Mini Player ───────────────────────────────────────────────────────

class _MiniPlayerTab extends StatefulWidget {
  @override
  State<_MiniPlayerTab> createState() => _MiniPlayerTabState();
}

class _MiniPlayerTabState extends State<_MiniPlayerTab> {
  var _track = _kTracks[0];
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
        children: [
          const _SectionHeader(
            'AppMiniPlayer',
            'Spotify / YouTube persistent mini-player with gestures',
            Iconsax.musicnote,
            Color(0xFF1DB954),
          ),
          const SizedBox(height: 12),
          ..._kTracks.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final isActive = _track.title == t.title;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _track = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _track.accentColor!.withOpacity(0.1)
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isActive
                          ? _track.accentColor!.withOpacity(0.4)
                          : cs.outlineVariant,
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: t.accentColor!.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Iconsax.musicnote,
                          color: t.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(t.subtitle,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isActive)
                      Icon(Iconsax.chart_1,
                          color: t.accentColor, size: 20),
                  ]),
                ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 250.ms),
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: Icon(_visible
                  ? Iconsax.eye_slash
                  : Iconsax.eye, size: 14),
              label: Text(_visible ? 'Hide player' : 'Show player'),
              onPressed: () => setState(() => _visible = !_visible),
            ),
          ),
        ],
      ),

      // Mini Player overlay
      if (_visible)
        AppMiniPlayer(
          data: _track,
          bottomPadding: 0,
          onPlayPause: () =>
              setState(() => _track = _track.copyWith(isPlaying: !_track.isPlaying)),
          onNext: () {
            final idx = _kTracks.indexWhere((t) => t.title == _track.title);
            setState(() => _track = _kTracks[(idx + 1) % _kTracks.length]);
          },
          onPrevious: () {
            final idx = _kTracks.indexWhere((t) => t.title == _track.title);
            setState(
                () => _track = _kTracks[(idx - 1 + _kTracks.length) % _kTracks.length]);
          },
          onLike: () =>
              setState(() => _track = _track.copyWith(isLiked: !_track.isLiked)),
          onDismiss: () => setState(() => _visible = false),
        ),
    ]);
  }
}

const _kTracks = [
  AppMiniPlayerData(
    title: 'Blinding Lights',
    subtitle: 'The Weeknd · After Hours',
    accentColor: Color(0xFFE91E63),
    duration: Duration(minutes: 3, seconds: 20),
    position: Duration(minutes: 1, seconds: 12),
  ),
  AppMiniPlayerData(
    title: 'Levitating',
    subtitle: 'Dua Lipa · Future Nostalgia',
    accentColor: Color(0xFF7C4DFF),
    duration: Duration(minutes: 3, seconds: 23),
    position: Duration(seconds: 45),
  ),
  AppMiniPlayerData(
    title: 'Stay',
    subtitle: 'The Kid LAROI, Justin Bieber',
    accentColor: Color(0xFF00BCD4),
    duration: Duration(minutes: 2, seconds: 21),
    position: Duration(minutes: 1),
  ),
  AppMiniPlayerData(
    title: 'As It Was',
    subtitle: 'Harry Styles · Harry\'s House',
    accentColor: Color(0xFFFF6B35),
    duration: Duration(minutes: 2, seconds: 37),
    position: Duration(seconds: 30),
  ),
];

// ─── Tab 5: Media Picker ──────────────────────────────────────────────────────

class _MediaPickerTab extends StatefulWidget {
  @override
  State<_MediaPickerTab> createState() => _MediaPickerTabState();
}

class _MediaPickerTabState extends State<_MediaPickerTab> {
  List<AppMediaFile> _picked = [];
  List<AppMediaFile> _docs = [];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          'AppMediaPicker',
          'Universal multi-source picker — camera · gallery · files',
          Iconsax.gallery,
          Color(0xFFEC4899),
        ),
        const SizedBox(height: 16),
        _DemoCard(
          label: 'Gallery Multi-Select',
          description: 'Pick up to 5 images from gallery, max 10 MB each',
          icon: Iconsax.gallery,
          color: const Color(0xFF4CAF50),
          onTap: () async {
            final files = await AppMediaPicker.pick(context,
                sources: [AppMediaSource.gallery], limit: 5, maxSizeInMb: 10);
            if (mounted) setState(() => _picked = files);
          },
        ),
        const SizedBox(height: 10),
        _DemoCard(
          label: 'Camera Capture',
          description: 'Single photo from camera, high quality',
          icon: Iconsax.camera,
          color: const Color(0xFF2196F3),
          onTap: () async {
            final files = await AppMediaPicker.pick(context,
                sources: [AppMediaSource.camera],
                imageQuality: ImageQuality.high);
            if (mounted) setState(() => _picked = files);
          },
        ),
        const SizedBox(height: 10),
        _DemoCard(
          label: 'Multi-Source Sheet',
          description: 'Camera + Gallery + Files — shows source selector',
          icon: Iconsax.gallery_add,
          color: const Color(0xFFFF5722),
          onTap: () async {
            final files = await AppMediaPicker.pick(context,
                sources: AppMediaSource.values,
                limit: 3,
                title: 'Upload Document',
                subtitle: 'Choose source');
            if (mounted) setState(() => _docs = files);
          },
        ),

        // Picked images
        if (_picked.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('Picked Images', '${_picked.length} file(s)',
              Iconsax.image, const Color(0xFF4CAF50)),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _picked
                  .map((f) => AppMediaFilePreview(
                      file: f,
                      onRemove: () => setState(() => _picked.remove(f))))
                  .toList(),
            ),
          ),
        ],

        // Picked docs
        if (_docs.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('Picked Files', '${_docs.length} file(s)',
              Iconsax.folder_open, const Color(0xFFFF5722)),
          const SizedBox(height: 10),
          ..._docs.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(children: [
                    Icon(Iconsax.document_text, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                              '${f.sizeInMb.toStringAsFixed(2)} MB · .${f.extension}',
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.close_circle, size: 16),
                      onPressed: () => setState(() => _docs.remove(f)),
                    ),
                  ]),
                ),
              )),
        ],

        const SizedBox(height: 24),
        const _SectionHeader('AppMediaPickerField',
            'Drop-in form field with live thumbnail grid',
            Iconsax.grid_1, Color(0xFF7C3AED)),
        const SizedBox(height: 12),
        AppMediaPickerField(
          label: 'Attach Documents',
          sources: AppMediaSource.values.toList(),
          limit: 4,
        ),
        const SizedBox(height: 40),
      ].animate(interval: 60.ms).fadeIn(duration: 250.ms).slideY(begin: 0.04),
    );
  }
}

class _PermissionsTab extends StatefulWidget {
  const _PermissionsTab();

  @override
  State<_PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<_PermissionsTab> with WidgetsBindingObserver {
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _refreshCounter++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Grouped permission types for showcase
    const groups = [
      (
        label: 'Camera & Media',
        color: Color(0xFF2196F3),
        icon: Iconsax.camera,
        types: [
          AppPermissionType.camera,
          AppPermissionType.microphone,
          AppPermissionType.photoLibrary,
          AppPermissionType.photoLibraryAdd,
        ],
      ),
      (
        label: 'Location',
        color: Color(0xFF4CAF50),
        icon: Iconsax.location,
        types: [
          AppPermissionType.locationWhenInUse,
          AppPermissionType.locationAlways,
        ],
      ),
      (
        label: 'Connectivity',
        color: Color(0xFF00BCD4),
        icon: Iconsax.bluetooth,
        types: [
          AppPermissionType.notifications,
          AppPermissionType.bluetooth,
          AppPermissionType.nearbyWifi,
        ],
      ),
      (
        label: 'Device & Data',
        color: Color(0xFF9C27B0),
        icon: Iconsax.archive,
        types: [
          AppPermissionType.contacts,
          AppPermissionType.storage,
          AppPermissionType.calendarRead,
          AppPermissionType.activityRecognition,
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const _SectionHeader(
          'AppPermissionManager',
          'Enterprise-grade platform-aware permission system',
          Iconsax.security,
          Color(0xFF7C3AED),
        ),
        const SizedBox(height: 8),

        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7C3AED).withOpacity(0.1),
                const Color(0xFF2563EB).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border:
                Border.all(color: const Color(0xFF7C3AED).withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Iconsax.info_circle,
                    size: 14, color: Color(0xFF7C3AED)),
                SizedBox(width: 6),
                Text('Platform-aware permission resolution',
                    style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              Text(
                'Android API 33+ uses granular media permissions · iOS 14+ supports limited photo access · Android 12+ splits Bluetooth',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Request All button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Iconsax.verify, size: 16),
            label: const Text('Request Common Permissions'),
            onPressed: () async {
              await AppPermissionManager.requestAll(
                context,
                [
                  AppPermissionType.camera,
                  AppPermissionType.microphone,
                  AppPermissionType.notifications,
                  AppPermissionType.locationWhenInUse,
                ],
              );
              _refresh();
            },
          ),
        ),
        const SizedBox(height: 20),

        // Permission groups
        ...groups.map((g) => _PermissionGroup(
              key: ValueKey('${g.label}_$_refreshCounter'),
              label: g.label,
              color: g.color,
              icon: g.icon,
              types: g.types,
            )),

        const SizedBox(height: 24),

        // Settings shortcut
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.setting, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Open App Settings',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('Manage permissions manually in system settings',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () async {
                await AppPermissionManager.openSettings();
                _refresh();
              },
              child: const Text('Open'),
            ),
          ]),
        ),
        const SizedBox(height: 40),
      ].animate(interval: 60.ms).fadeIn(duration: 250.ms).slideY(begin: 0.04),
    );
  }
}

class _PermissionGroup extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final List<AppPermissionType> types;

  const _PermissionGroup({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.types,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface)),
          ]),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: types.asMap().entries.map((e) {
                final i = e.key;
                final type = e.value;
                final isLast = i == types.length - 1;
                return Column(children: [
                  AppPermissionTile(
                    type: type,
                    onGranted: () {},
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: 56,
                        color: cs.outlineVariant),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SectionHeader(this.title, this.subtitle, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String label, description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(description,
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Iconsax.play_circle, color: color, size: 22),
          ]),
        ),
      ),
    );
  }
}
