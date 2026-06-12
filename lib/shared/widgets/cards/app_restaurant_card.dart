// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class AppRestaurantOffer {
  final String label;
  final Color? color;
  const AppRestaurantOffer(this.label, {this.color});
}

class AppRestaurantCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final double rating;
  final int? ratingCount;
  final String? deliveryTime; // "25–30 min"
  final String? deliveryFee; // "Free delivery" | "₹25 delivery"
  final String? distance; // "1.2 km"
  final List<String> cuisines;
  final List<AppRestaurantOffer> offers;
  final String? promoLabel; // "50% OFF up to ₹100"
  final bool isPromoted;
  final bool isFavorite;
  final bool isClosed;
  final String? closedMessage;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final AppRestaurantCardStyle style;

  const AppRestaurantCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.rating = 4.0,
    this.ratingCount,
    this.deliveryTime,
    this.deliveryFee,
    this.distance,
    this.cuisines = const [],
    this.offers = const [],
    this.promoLabel,
    this.isPromoted = false,
    this.isFavorite = false,
    this.isClosed = false,
    this.closedMessage,
    this.onTap,
    this.onFavorite,
    this.style = AppRestaurantCardStyle.vertical,
  });

  @override
  State<AppRestaurantCard> createState() => _AppRestaurantCardState();
}

enum AppRestaurantCardStyle { vertical, horizontal, compact }

class _AppRestaurantCardState extends State<AppRestaurantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case AppRestaurantCardStyle.horizontal:
        return _buildHorizontal(context);
      case AppRestaurantCardStyle.compact:
        return _buildCompact(context);
      case AppRestaurantCardStyle.vertical:
        return _buildVertical(context);
    }
  }

  Widget _buildVertical(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) => _pressCtrl.forward(),
      onTapCancel: () => _pressCtrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RestaurantImage(
                imageUrl: widget.imageUrl,
                isClosed: widget.isClosed,
                closedMessage: widget.closedMessage,
                isPromoted: widget.isPromoted,
                promoLabel: widget.promoLabel,
                isFav: _isFav,
                onFavTap: () => setState(() => _isFav = !_isFav),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: _RestaurantInfo(
                  name: widget.name,
                  rating: widget.rating,
                  ratingCount: widget.ratingCount,
                  cuisines: widget.cuisines,
                  deliveryTime: widget.deliveryTime,
                  deliveryFee: widget.deliveryFee,
                  distance: widget.distance,
                  offers: widget.offers,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) => _pressCtrl.forward(),
      onTapCancel: () => _pressCtrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Image
              SizedBox(
                width: 100,
                child: _RestaurantImage(
                  imageUrl: widget.imageUrl,
                  isClosed: widget.isClosed,
                  isFav: _isFav,
                  onFavTap: () => setState(() => _isFav = !_isFav),
                  compact: true,
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _RatingBadge(rating: widget.rating, compact: true),
                          const SizedBox(width: 6),
                          if (widget.deliveryTime != null)
                            Text(
                              widget.deliveryTime!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                      if (widget.cuisines.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.cuisines.take(2).join(' • '),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                color: cs.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImageContent(widget.imageUrl, widget.isClosed),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.name,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.deliveryTime != null)
            Text(
              widget.deliveryTime!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent(String? url, bool closed) {
    if (url == null) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.restaurant_rounded, color: Color(0xFF94A3B8), size: 32),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const _ImageShimmer(),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.restaurant_rounded, color: Color(0xFF94A3B8), size: 32),
      ),
    );
  }
}

// ─── Restaurant Image Section ─────────────────────────────────────────────────
class _RestaurantImage extends StatelessWidget {
  final String? imageUrl;
  final bool isClosed;
  final String? closedMessage;
  final bool isPromoted;
  final String? promoLabel;
  final bool isFav;
  final VoidCallback? onFavTap;
  final bool compact;

  const _RestaurantImage({
    this.imageUrl,
    this.isClosed = false,
    this.closedMessage,
    this.isPromoted = false,
    this.promoLabel,
    this.isFav = false,
    this.onFavTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: compact ? 1.0 : 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => const _ImageShimmer(),
              errorWidget: (_, __, ___) => _PlaceholderImage(),
            )
          else
            _PlaceholderImage(),

          // Closed overlay
          if (isClosed)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      closedMessage ?? 'Currently Closed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom gradient for promo
          if (!compact && promoLabel != null)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
            ),

          // Promo label at bottom-left
          if (!compact && promoLabel != null)
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  promoLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          // Promoted badge
          if (!compact && isPromoted)
            Positioned(
              left: 10,
              top: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    color: Colors.white.withOpacity(0.85),
                    child: const Text(
                      'PROMOTED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Favorite button
          if (!compact && onFavTap != null)
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap: onFavTap,
                child: AnimatedScale(
                  scale: isFav ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 32,
                        height: 32,
                        color: Colors.white.withOpacity(0.7),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          size: 16,
                          color: isFav ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Restaurant Info Section ──────────────────────────────────────────────────
class _RestaurantInfo extends StatelessWidget {
  final String name;
  final double rating;
  final int? ratingCount;
  final List<String> cuisines;
  final String? deliveryTime;
  final String? deliveryFee;
  final String? distance;
  final List<AppRestaurantOffer> offers;

  const _RestaurantInfo({
    required this.name,
    required this.rating,
    this.ratingCount,
    required this.cuisines,
    this.deliveryTime,
    this.deliveryFee,
    this.distance,
    required this.offers,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + rating row
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _RatingBadge(rating: rating),
          ],
        ),
        const SizedBox(height: 3),

        // Cuisines
        if (cuisines.isNotEmpty)
          Text(
            cuisines.take(3).join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 6),

        // Delivery info row
        Row(
          children: [
            if (deliveryTime != null) ...[
              Icon(Icons.schedule_outlined, size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(
                deliveryTime!,
                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
            ],
            if (distance != null) ...[
              Icon(Icons.place_outlined, size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(
                distance!,
                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
            ],
            if (deliveryFee != null) ...[
              Icon(
                Icons.electric_moped_outlined,
                size: 13,
                color: deliveryFee!.toLowerCase().contains('free')
                    ? const Color(0xFF16A34A)
                    : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Text(
                deliveryFee!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: deliveryFee!.toLowerCase().contains('free')
                      ? const Color(0xFF16A34A)
                      : cs.onSurfaceVariant,
                  fontWeight: deliveryFee!.toLowerCase().contains('free')
                      ? FontWeight.w600
                      : null,
                ),
              ),
            ],
          ],
        ),

        // Offers
        if (offers.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...offers.take(2).map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      size: 12,
                      color: o.color ?? const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      o.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: o.color ?? const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

// ─── Rating Badge ─────────────────────────────────────────────────────────────
class _RatingBadge extends StatelessWidget {
  final double rating;
  final bool compact;
  const _RatingBadge({required this.rating, this.compact = false});

  Color _ratingColor() {
    if (rating >= 4.5) return const Color(0xFF16A34A);
    if (rating >= 4.0) return const Color(0xFF22C55E);
    if (rating >= 3.5) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: _ratingColor(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: compact ? 9 : 11,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.restaurant_menu_rounded, color: Color(0xFFCBD5E1), size: 40),
      ),
    );
  }
}

class _ImageShimmer extends StatefulWidget {
  const _ImageShimmer();
  @override
  State<_ImageShimmer> createState() => _ImageShimmerState();
}

class _ImageShimmerState extends State<_ImageShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFFE2E8F0),
              Color.lerp(const Color(0xFFE2E8F0), const Color(0xFFF8FAFC), _anim.value)!,
              const Color(0xFFE2E8F0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Restaurant List ──────────────────────────────────────────────────────────
/// Full scrollable restaurant list like Zomato's main feed.
class AppRestaurantList extends StatelessWidget {
  final List<AppRestaurantCardData> restaurants;
  final EdgeInsets padding;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final String? emptyMessage;

  const AppRestaurantList({
    super.key,
    required this.restaurants,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.onLoadMore,
    this.isLoading = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty && !isLoading) {
      return Padding(
        padding: padding,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_outlined, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text(
                emptyMessage ?? 'No restaurants found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...restaurants.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left, i == 0 ? 0 : 14, padding.right, 0,
            ),
            child: AppRestaurantCard(
              name: r.name,
              imageUrl: r.imageUrl,
              rating: r.rating,
              ratingCount: r.ratingCount,
              deliveryTime: r.deliveryTime,
              deliveryFee: r.deliveryFee,
              distance: r.distance,
              cuisines: r.cuisines,
              offers: r.offers,
              promoLabel: r.promoLabel,
              isPromoted: r.isPromoted,
              isFavorite: r.isFavorite,
              isClosed: r.isClosed,
              onTap: r.onTap,
            )
                .animate(delay: Duration(milliseconds: 60 * i))
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.06, duration: 300.ms),
          );
        }),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class AppRestaurantCardData {
  final String name;
  final String? imageUrl;
  final double rating;
  final int? ratingCount;
  final String? deliveryTime;
  final String? deliveryFee;
  final String? distance;
  final List<String> cuisines;
  final List<AppRestaurantOffer> offers;
  final String? promoLabel;
  final bool isPromoted;
  final bool isFavorite;
  final bool isClosed;
  final VoidCallback? onTap;

  const AppRestaurantCardData({
    required this.name,
    this.imageUrl,
    this.rating = 4.0,
    this.ratingCount,
    this.deliveryTime,
    this.deliveryFee,
    this.distance,
    this.cuisines = const [],
    this.offers = const [],
    this.promoLabel,
    this.isPromoted = false,
    this.isFavorite = false,
    this.isClosed = false,
    this.onTap,
  });
}
