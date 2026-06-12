// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── App Product Card ─────────────────────────────────────────────────────────
/// Zomato/Zepto-quality product card with image, badge, rating, add-to-cart.
/// Supports hero animations, shimmer loading, and fully configurable layout.
class AppProductCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Widget? imagePlaceholder;
  final double? price;
  final double? originalPrice;
  final double? discountPercent;
  final double? rating;
  final int? reviewCount;
  final String? badge;
  final Color? badgeColor;
  final bool isFavorite;
  final bool inCart;
  final int cartQuantity;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final String? heroTag;
  final bool showAddButton;
  final AppProductCardSize size;
  final List<String>? tags;
  final Widget? bottomWidget;

  const AppProductCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.imagePlaceholder,
    this.price,
    this.originalPrice,
    this.discountPercent,
    this.rating,
    this.reviewCount,
    this.badge,
    this.badgeColor,
    this.isFavorite = false,
    this.inCart = false,
    this.cartQuantity = 0,
    this.onTap,
    this.onFavoriteToggle,
    this.onAdd,
    this.onRemove,
    this.heroTag,
    this.showAddButton = true,
    this.size = AppProductCardSize.medium,
    this.tags,
    this.bottomWidget,
  });

  @override
  State<AppProductCard> createState() => _AppProductCardState();
}

enum AppProductCardSize { small, medium, large, horizontal }

class _AppProductCardState extends State<AppProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    setState(() => _pressed = true);
    _pressCtrl.reverse();
  }

  void _handleTapUp(_) {
    setState(() => _pressed = false);
    _pressCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (widget.size == AppProductCardSize.horizontal) {
      return _buildHorizontal(context, theme, cs);
    }
    return _buildVertical(context, theme, cs);
  }

  Widget _buildVertical(BuildContext context, ThemeData theme, ColorScheme cs) {
    final imgHeight = switch (widget.size) {
      AppProductCardSize.small => 110.0,
      AppProductCardSize.medium => 150.0,
      AppProductCardSize.large => 200.0,
      _ => 150.0,
    };

    Widget card = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: () {
        setState(() => _pressed = false);
        _pressCtrl.forward();
      },
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(_pressed ? 0.04 : 0.08),
                blurRadius: _pressed ? 4 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image
              _buildImageSection(
                context,
                cs,
                height: imgHeight,
                radius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),

              // ── Content
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (widget.rating != null) ...[
                      const SizedBox(height: 4),
                      _RatingRow(
                        rating: widget.rating!,
                        reviewCount: widget.reviewCount,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _PriceRow(
                            price: widget.price,
                            originalPrice: widget.originalPrice,
                            scheme: cs,
                          ),
                        ),
                        if (widget.showAddButton)
                          _AddButton(
                            inCart: widget.inCart,
                            quantity: widget.cartQuantity,
                            onAdd: widget.onAdd,
                            onRemove: widget.onRemove,
                          ),
                      ],
                    ),
                    if (widget.bottomWidget != null) ...[
                      const SizedBox(height: 6),
                      widget.bottomWidget!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: card);
    }
    return card;
  }

  Widget _buildHorizontal(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
  ) {
    Widget card = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: () {
        setState(() => _pressed = false);
        _pressCtrl.forward();
      },
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildImageSection(
                context,
                cs,
                height: 100,
                width: 100,
                radius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _PriceRow(
                              price: widget.price,
                              originalPrice: widget.originalPrice,
                              scheme: cs,
                            ),
                          ),
                          if (widget.showAddButton)
                            _AddButton(
                              inCart: widget.inCart,
                              quantity: widget.cartQuantity,
                              onAdd: widget.onAdd,
                              onRemove: widget.onRemove,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.heroTag != null) return Hero(tag: widget.heroTag!, child: card);
    return card;
  }

  Widget _buildImageSection(
    BuildContext context,
    ColorScheme cs, {
    required double height,
    double? width,
    required BorderRadius radius,
  }) {
    Widget img;
    if (widget.imageUrl != null) {
      img = CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        width: width ?? double.infinity,
        height: height,
        placeholder: (_, __) => _shimmerBox(cs, height: height, width: width),
        errorWidget: (_, __, ___) =>
            _placeholderBox(cs, height: height, width: width),
      );
    } else {
      img =
          widget.imagePlaceholder ??
          _placeholderBox(cs, height: height, width: width);
    }

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          SizedBox(height: height, width: width ?? double.infinity, child: img),
          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                ),
              ),
            ),
          ),
          // Discount badge
          if (widget.discountPercent != null)
            Positioned(
              top: 8,
              left: 8,
              child: _DiscountBadge(percent: widget.discountPercent!),
            ),
          // Custom badge
          if (widget.badge != null)
            Positioned(
              top: 8,
              left: 8,
              child: _CustomBadge(
                label: widget.badge!,
                color: widget.badgeColor,
              ),
            ),
          // Favorite button
          if (widget.onFavoriteToggle != null)
            Positioned(
              top: 6,
              right: 6,
              child: _FavoriteButton(
                isFavorite: widget.isFavorite,
                onTap: widget.onFavoriteToggle!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _shimmerBox(ColorScheme cs, {required double height, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: cs.surfaceContainerHighest,
    );
  }

  Widget _placeholderBox(
    ColorScheme cs, {
    required double height,
    double? width,
  }) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  const _RatingRow({required this.rating, this.reviewCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 13, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 3),
          Text(
            '(${_formatCount(reviewCount!)})',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _PriceRow extends StatelessWidget {
  final double? price;
  final double? originalPrice;
  final ColorScheme scheme;
  const _PriceRow({this.price, this.originalPrice, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (price == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '₹${price!.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        if (originalPrice != null && originalPrice! > price!) ...[
          const SizedBox(width: 4),
          Text(
            '₹${originalPrice!.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool inCart;
  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  const _AddButton({
    required this.inCart,
    required this.quantity,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!inCart || quantity == 0) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          height: 30,
          width: 60,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      ).animate().scale(duration: 200.ms, curve: Curves.elasticOut);
    }
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const SizedBox(
              width: 28,
              height: 30,
              child: Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const SizedBox(
              width: 28,
              height: 30,
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.elasticOut);
  }
}

class _DiscountBadge extends StatelessWidget {
  final double percent;
  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${percent.toStringAsFixed(0)}% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CustomBadge extends StatelessWidget {
  final String label;
  final Color? color;
  const _CustomBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onTap();
      },
      child: ScaleTransition(
        scale: Tween(
          begin: 1.0,
          end: 1.3,
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)),
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 16,
            color: widget.isFavorite ? Colors.red : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// ─── Feature Card (hero sections / promo) ────────────────────────────────────
/// Large gradient card for hero sections, featured items, or promotions.
class AppFeatureCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final Widget? action;
  final String? heroTag;
  final double height;
  final List<String>? tags;

  const AppFeatureCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.gradientColors = const [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
    this.onTap,
    this.action,
    this.heroTag,
    this.height = 180,
    this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background image
            if (imageUrl != null)
              Positioned(
                right: -20,
                top: -20,
                bottom: -20,
                width: height * 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  child: Opacity(
                    opacity: 0.25,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            // Noise texture overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (subtitle != null) const SizedBox(height: 8),
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (tags != null)
                        ...tags!.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (action != null) action!,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (heroTag != null) return Hero(tag: heroTag!, child: card);
    return card;
  }
}

// ─── Category Chip ────────────────────────────────────────────────────────────
class AppCategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imageUrl;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  const AppCategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.imageUrl,
    this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? effectiveColor : effectiveColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected ? effectiveColor : effectiveColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 16,
                  height: 16,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(
                    icon ?? Icons.category,
                    size: 14,
                    color: selected ? Colors.white : effectiveColor,
                  ),
                ),
              )
            else if (icon != null)
              Icon(
                icon!,
                size: 14,
                color: selected ? Colors.white : effectiveColor,
              ),
            if (icon != null || imageUrl != null) const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Strip ───────────────────────────────────────────────────────────
class AppCategoryStrip extends StatefulWidget {
  final List<AppCategoryItem> categories;
  final int initialSelected;
  final ValueChanged<int>? onSelected;
  final ScrollPhysics physics;
  final EdgeInsets padding;

  const AppCategoryStrip({
    super.key,
    required this.categories,
    this.initialSelected = 0,
    this.onSelected,
    this.physics = const BouncingScrollPhysics(),
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<AppCategoryStrip> createState() => _AppCategoryStripState();
}

class AppCategoryItem {
  final String label;
  final IconData? icon;
  final String? imageUrl;
  final Color? color;
  const AppCategoryItem(this.label, {this.icon, this.imageUrl, this.color});
}

class _AppCategoryStripState extends State<AppCategoryStrip> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: widget.physics,
      padding: widget.padding,
      child: Row(
        children: widget.categories.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Padding(
            padding: EdgeInsets.only(
              right: i < widget.categories.length - 1 ? 8 : 0,
            ),
            child:
                AppCategoryChip(
                      label: c.label,
                      icon: c.icon,
                      imageUrl: c.imageUrl,
                      color: c.color,
                      selected: _selected == i,
                      onTap: () {
                        setState(() => _selected = i);
                        widget.onSelected?.call(i);
                      },
                    )
                    .animate(delay: Duration(milliseconds: 30 * i))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1, duration: 300.ms),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
/// KPI/metric display card — used in dashboards, analytics sections.
class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final String? trend;
  final bool trendUp;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    this.trend,
    this.trendUp = true,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final effectiveColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon ?? Icons.analytics_outlined,
                    size: 18,
                    color: effectiveColor,
                  ),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (trendUp
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626))
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 11,
                          color: trendUp
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trend!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: trendUp
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            if (subValue != null) ...[
              const SizedBox(height: 4),
              Text(
                subValue!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
