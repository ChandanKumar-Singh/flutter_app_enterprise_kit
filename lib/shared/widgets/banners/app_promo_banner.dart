// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Promo Banner Model ───────────────────────────────────────────────────────
class AppPromoBannerItem {
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final String? imageUrl;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final Color? textColor;

  const AppPromoBannerItem({
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.imageUrl,
    this.gradientColors = const [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
    this.onTap,
    this.textColor,
  });
}

// ─── App Promo Banner ─────────────────────────────────────────────────────────
/// Auto-scrolling full-width promo/offer carousel — Zomato/Zepto style.
class AppPromoBanner extends StatefulWidget {
  final List<AppPromoBannerItem> items;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final EdgeInsets margin;
  final bool showIndicator;

  const AppPromoBanner({
    super.key,
    required this.items,
    this.height = 160,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.showIndicator = true,
  });

  @override
  State<AppPromoBanner> createState() => _AppPromoBannerState();
}

class _AppPromoBannerState extends State<AppPromoBanner> {
  late PageController _pageCtrl;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 1.0);
    if (widget.autoPlay && widget.items.length > 1) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted) return;
      final next = (_current + 1) % widget.items.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return _BannerCard(item: item, height: widget.height, margin: widget.margin);
            },
          ),
        ),
        if (widget.showIndicator && widget.items.length > 1) ...[
          const SizedBox(height: 10),
          _DotIndicator(count: widget.items.length, current: _current),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final AppPromoBannerItem item;
  final double height;
  final EdgeInsets margin;
  const _BannerCard({required this.item, required this.height, required this.margin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = item.textColor ?? Colors.white;

    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: item.gradientColors.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Stack(
          children: [
            // Background image overlay
            if (item.imageUrl != null)
              Positioned(
                right: 0, top: 0, bottom: 0,
                width: height * 1.1,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            // Gradient over the image
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      item.gradientColors.first.withOpacity(0.95),
                      item.gradientColors.first.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Circular decorations
            Positioned(
              right: -30, top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 30, bottom: -40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!.toUpperCase(),
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  if (item.subtitle != null) const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (item.ctaLabel != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        item.ctaLabel!,
                        style: TextStyle(
                          color: item.gradientColors.first,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.outlineVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        );
      }),
    );
  }
}

// ─── Info Strip ───────────────────────────────────────────────────────────────
/// Horizontally scrollable trust/USP strip (free delivery, 10min delivery, etc.)
class AppInfoStrip extends StatelessWidget {
  final List<AppInfoStripItem> items;
  final EdgeInsets padding;

  const AppInfoStrip({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Row(
            children: [
              _InfoStripTile(item: item),
              if (!isLast)
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: cs.outlineVariant,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class AppInfoStripItem {
  final IconData icon;
  final String label;
  final Color? color;
  const AppInfoStripItem(this.icon, this.label, {this.color});
}

class _InfoStripTile extends StatelessWidget {
  final AppInfoStripItem item;
  const _InfoStripTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = item.color ?? cs.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 14, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          item.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Creates a ready-made AppInfoStrip with common USP items.
AppInfoStrip appInfoStripDefault() {
  return const AppInfoStrip(
    items: [
      AppInfoStripItem(Iconsax.flash, '10-min delivery', color: Color(0xFF7C3AED)),
      AppInfoStripItem(Iconsax.tag, 'Best prices', color: Color(0xFF16A34A)),
      AppInfoStripItem(Iconsax.verify, '100% safe', color: Color(0xFF0284C7)),
      AppInfoStripItem(Iconsax.rotate_left, 'Easy returns', color: Color(0xFFD97706)),
    ],
  );
}
