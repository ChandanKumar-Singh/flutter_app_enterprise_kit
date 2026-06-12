// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
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

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0.5,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
              title: Text('Advanced Components',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF7C3AED), cs.primary],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
                  child: Text(
                    'Giant-app UX/UI patterns',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.6)),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: cs.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              tabs: const [
                Tab(text: 'Sheets'),
                Tab(text: 'Previews'),
                Tab(text: 'Popovers'),
                Tab(text: 'Mini Player'),
                Tab(text: 'Media Picker'),
              ],
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
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('AppSnappingSheet', 'Uber / Airbnb multi-snap sheets'),
        const SizedBox(height: 12),

        // Uber-style map sheet
        _DemoCard(
          label: 'Uber-style Map Sheet',
          description: 'Multi-snap (35%, 60%, 92%) with scrim + rubber-band physics',
          icon: Icons.map_rounded,
          color: const Color(0xFF1B1B2F),
          onTap: () => _showMapSheet(context),
        ),

        const SizedBox(height: 10),

        // Filter sheet
        _DemoCard(
          label: 'Filter Panel Sheet',
          description: 'Chips + range slider — AppFilterSheet preset',
          icon: Icons.tune_rounded,
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

        // Options sheet
        _DemoCard(
          label: 'Options Sheet',
          description: 'iOS-style action list — AppOptionSheet preset',
          icon: Icons.list_rounded,
          color: const Color(0xFF16A34A),
          onTap: () => AppOptionSheet.show(
            context: context,
            title: 'Share via',
            subtitle: 'Choose how to share this item',
            options: [
              const AppOptionItem(icon: Icons.link_rounded, label: 'Copy Link'),
              const AppOptionItem(icon: Icons.share_rounded, label: 'Share Sheet'),
              const AppOptionItem(icon: Icons.bookmark_border_rounded, label: 'Save'),
              const AppOptionItem(icon: Icons.report_rounded, label: 'Report', isDestructive: true),
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
          icon: const Icon(Icons.tune_rounded, size: 14),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
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
          // Fake roads
          ...List.generate(4, (i) => Positioned(
            top: 50.0 + i * 80,
            left: 0, right: 0,
            height: 8,
            child: Container(color: Colors.white.withOpacity(0.7)),
          )),
          ...List.generate(3, (i) => Positioned(
            left: 60.0 + i * 90,
            top: 0, bottom: 0,
            width: 8,
            child: Container(color: Colors.white.withOpacity(0.7)),
          )),
          // Location pin
          const Positioned(
            top: 120, left: 0, right: 0,
            child: Center(
              child: Icon(Icons.location_on_rounded, color: Colors.red, size: 40),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final names = ['Burger Palace', 'Spice Garden', 'The Pasta Place', 'Sushi Wave', 'Green Bowl', 'Taco Town'];
    final distances = ['0.4 km', '0.8 km', '1.2 km', '1.5 km', '1.9 km', '2.3 km'];
    final times = ['12 min', '18 min', '22 min', '28 min', '35 min', '40 min'];
    final ratings = [4.7, 4.3, 4.5, 4.8, 4.1, 4.6];

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
                width: 52, height: 52,
                color: const Color(0xFFFF6B35).withOpacity(0.15),
                child: Icon(Icons.restaurant_rounded, color: const Color(0xFFFF6B35), size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(names[index % names.length],
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                      const SizedBox(width: 3),
                      Text('${ratings[index % ratings.length]}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                      Text('  •  ${distances[index % distances.length]}  •  ${times[index % times.length]}',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 18),
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
        _SectionHeader('AppContextPreview', 'Instagram / Telegram 3D-touch haptic preview'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 8),
              Text('Long-press any card below', style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...List.generate(4, (i) {
          final titles = ['Margherita Pizza', 'Chicken Tikka', 'Sushi Platter', 'Avocado Toast'];
          final prices = ['₹299', '₹449', '₹599', '₹199'];
          final descriptions = [
            'Classic Italian pizza with fresh mozzarella and basil',
            'Grilled chicken in aromatic spices, served with mint chutney',
            'Fresh sashimi and rolls, artfully plated with wasabi',
            'Toasted sourdough with smashed avocado and poached egg',
          ];
          final colors = [const Color(0xFFFF6B35), const Color(0xFFFF9800), const Color(0xFF2196F3), const Color(0xFF4CAF50)];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppContextPreview(
              previewHeight: 260,
              actions: [
                AppQuickAction(
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'Add to Cart',
                  onTap: () {},
                ),
                AppQuickAction(
                  icon: Icons.favorite_border_rounded,
                  label: 'Save',
                  onTap: () {},
                ),
                AppQuickAction(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {},
                ),
                AppQuickAction(
                  icon: Icons.report_rounded,
                  label: 'Report',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
              preview: _FoodPreviewCard(
                title: titles[i],
                description: descriptions[i],
                price: prices[i],
                color: colors[i],
              ),
              child: _FoodListItem(
                title: titles[i],
                price: prices[i],
                color: colors[i],
              ),
            ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 250.ms).slideY(begin: 0.04),
          );
        }),
      ],
    );
  }
}

class _FoodPreviewCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final Color color;

  const _FoodPreviewCard({required this.title, required this.description, required this.price, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image area
        Container(
          height: 160,
          color: color.withOpacity(0.2),
          child: Center(
            child: Icon(Icons.restaurant_menu_rounded, color: color, size: 64),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 6),
              Text(description, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(price, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
                  FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
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
  final String title;
  final String price;
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
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fastfood_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(price, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.add_circle_rounded, color: color),
        ],
      ),
    );
  }
}

// ─── Tab 3: Popovers ──────────────────────────────────────────────────────────

class _PopoverTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('AppPopover', 'Anchor-positioned floating cards with auto-flip'),
        const SizedBox(height: 16),

        // Row of popover buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppPopoverAnchor(
              position: AppPopoverPosition.bottom,
              popover: _InfoPopoverContent(),
              child: FilledButton.icon(
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('Info Popover'),
                onPressed: null,
              ),
            ),
            AppMenuPopover(
              items: [
                AppPopoverMenuItem(icon: Icons.edit_rounded, label: 'Edit', onTap: () {}),
                AppPopoverMenuItem(icon: Icons.copy_rounded, label: 'Duplicate', onTap: () {}),
                AppPopoverMenuItem(icon: Icons.share_rounded, label: 'Share', onTap: () {}),
                AppPopoverMenuItem(icon: Icons.delete_rounded, label: 'Delete', isDestructive: true, onTap: () {}),
              ],
              child: OutlinedButton.icon(
                icon: const Icon(Icons.more_horiz_rounded, size: 16),
                label: const Text('Menu Popover'),
                onPressed: null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        _SectionHeader('AppAppBar', 'Glassmorphic adaptive bar — transparent → blur on scroll'),
        const SizedBox(height: 12),

        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: const _AppBarPreview(),
        ),
      ].animate(interval: 80.ms).fadeIn(duration: 250.ms).slideY(begin: 0.04),
    );
  }
}

class _InfoPopoverContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            const Text('4.8 Rating', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Based on 1,240 reviews', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 10),
        _RatingRow('Food', 4.9),
        _RatingRow('Service', 4.7),
        _RatingRow('Packaging', 4.8),
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
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 11))),
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
          Text(rating.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
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
    return Stack(
      children: [
        ListView.builder(
          controller: _sc,
          itemCount: 20,
          itemBuilder: (_, i) => ListTile(
            title: Text('Item $i'),
            subtitle: Text('Scroll to see glassmorphic effect'),
          ),
        ),
        AppAppBar(
          title: 'Glassmorphic Bar',
          behavior: AppBarScrollBehavior.glassmorphic,
          scrollController: _sc,
          actions: [
            IconButton(icon: const Icon(Icons.search_rounded), onPressed: null),
          ],
        ),
      ],
    );
  }
}

// ─── Tab 4: Mini Player ───────────────────────────────────────────────────────

class _MiniPlayerTab extends StatefulWidget {
  @override
  State<_MiniPlayerTab> createState() => _MiniPlayerTabState();
}

class _MiniPlayerTabState extends State<_MiniPlayerTab> {
  var _track = const AppMiniPlayerData(
    title: 'Blinding Lights',
    subtitle: 'The Weeknd • After Hours',
    accentColor: Color(0xFFE91E63),
    isPlaying: false,
    duration: Duration(minutes: 3, seconds: 20),
    position: Duration(minutes: 1, seconds: 12),
  );
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
          children: [
            _SectionHeader('AppMiniPlayer', 'Spotify / YouTube persistent mini-player'),
            const SizedBox(height: 12),

            // Track selector
            ...List.generate(_tracks.length, (i) {
              final t = _tracks[i];
              final isActive = _track.title == t.title;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _track = t),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive ? _track.accentColor!.withOpacity(0.1) : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isActive ? _track.accentColor!.withOpacity(0.4) : cs.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: t.accentColor!.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.music_note_rounded, color: t.accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(t.subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (isActive) Icon(Icons.equalizer_rounded, color: t.accentColor, size: 20),
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 250.ms).slideY(begin: 0.04),
              );
            }),

            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.visibility_off_rounded, size: 14),
                label: const Text('Hide player'),
                onPressed: () => setState(() => _visible = false),
              ),
            ),
            if (!_visible)
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.visibility_rounded, size: 14),
                  label: const Text('Show player'),
                  onPressed: () => setState(() => _visible = true),
                ),
              ),
          ],
        ),

        // Mini Player
        if (_visible)
          AppMiniPlayer(
            data: _track,
            bottomPadding: 0,
            onPlayPause: () => setState(() => _track = _track.copyWith(isPlaying: !_track.isPlaying)),
            onNext: () {
              final idx = _tracks.indexWhere((t) => t.title == _track.title);
              setState(() => _track = _tracks[(idx + 1) % _tracks.length]);
            },
            onPrevious: () {
              final idx = _tracks.indexWhere((t) => t.title == _track.title);
              setState(() => _track = _tracks[(idx - 1 + _tracks.length) % _tracks.length]);
            },
            onLike: () => setState(() => _track = _track.copyWith(isLiked: !_track.isLiked)),
            onDismiss: () => setState(() => _visible = false),
          ),
      ],
    );
  }
}

final _tracks = [
  const AppMiniPlayerData(
    title: 'Blinding Lights',
    subtitle: 'The Weeknd • After Hours',
    accentColor: Color(0xFFE91E63),
    duration: Duration(minutes: 3, seconds: 20),
    position: Duration(minutes: 1, seconds: 12),
  ),
  const AppMiniPlayerData(
    title: 'Levitating',
    subtitle: 'Dua Lipa • Future Nostalgia',
    accentColor: Color(0xFF7C4DFF),
    duration: Duration(minutes: 3, seconds: 23),
    position: Duration(seconds: 45),
  ),
  const AppMiniPlayerData(
    title: 'Stay',
    subtitle: 'The Kid LAROI, Justin Bieber',
    accentColor: Color(0xFF00BCD4),
    duration: Duration(minutes: 2, seconds: 21),
    position: Duration(minutes: 1),
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
        _SectionHeader('AppMediaPicker', 'Universal multi-source picker (camera / gallery / files)'),
        const SizedBox(height: 16),

        // Gallery multi-select
        _DemoCard(
          label: 'Gallery Multi-Select',
          description: 'Pick up to 5 images from gallery, max 10MB each',
          icon: Icons.photo_library_rounded,
          color: const Color(0xFF4CAF50),
          onTap: () async {
            final files = await AppMediaPicker.pick(
              context,
              sources: [AppMediaSource.gallery],
              limit: 5,
              maxSizeInMb: 10,
            );
            if (mounted) setState(() => _picked = files);
          },
        ),

        const SizedBox(height: 10),

        // Camera
        _DemoCard(
          label: 'Camera Capture',
          description: 'Single photo from camera, high quality',
          icon: Icons.camera_alt_rounded,
          color: const Color(0xFF2196F3),
          onTap: () async {
            final files = await AppMediaPicker.pick(
              context,
              sources: [AppMediaSource.camera],
              imageQuality: ImageQuality.high,
            );
            if (mounted) setState(() => _picked = files);
          },
        ),

        const SizedBox(height: 10),

        // Any source
        _DemoCard(
          label: 'Multi-Source Sheet',
          description: 'Camera + Gallery + Files — shows source selector',
          icon: Icons.add_photo_alternate_rounded,
          color: const Color(0xFFFF5722),
          onTap: () async {
            final files = await AppMediaPicker.pick(
              context,
              sources: AppMediaSource.values,
              limit: 3,
              title: 'Upload Document',
              subtitle: 'Choose source',
            );
            if (mounted) setState(() => _docs = files);
          },
        ),

        // Results
        if (_picked.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('Picked Images', '${_picked.length} file(s)'),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _picked.map((f) => AppMediaFilePreview(
                file: f,
                onRemove: () => setState(() => _picked.remove(f)),
              )).toList(),
            ),
          ),
        ],

        if (_docs.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('Picked Files', '${_docs.length} file(s)'),
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
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file_rounded, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${f.sizeInMb.toStringAsFixed(2)} MB • .${f.extension}',
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () => setState(() => _docs.remove(f)),
                  ),
                ],
              ),
            ),
          )),
        ],

        const SizedBox(height: 24),

        // AppMediaPickerField form demo
        _SectionHeader('AppMediaPickerField', 'Drop-in form field with thumbnail grid'),
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

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String label;
  final String description;
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
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
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(description, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.play_circle_outline_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
