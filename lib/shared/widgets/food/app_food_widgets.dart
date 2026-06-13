// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Food Category Model ──────────────────────────────────────────────────────
class AppFoodCategory {
  final String label;
  final String? imageUrl;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const AppFoodCategory({
    required this.label,
    this.imageUrl,
    this.icon,
    this.color,
    this.onTap,
  });
}

// ─── Food Category Wheel ─────────────────────────────────────────────────────
/// "What's on your mind?" horizontal scrollable food category strip — Zomato style.
class AppFoodCategoryWheel extends StatelessWidget {
  final String title;
  final List<AppFoodCategory> categories;
  final double imageSize;
  final EdgeInsets padding;
  final bool showTitle;

  const AppFoodCategoryWheel({
    super.key,
    this.title = "What's on your mind?",
    required this.categories,
    this.imageSize = 72,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Padding(
            padding: padding,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          height: imageSize + 28,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: padding,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              return Padding(
                padding: EdgeInsets.only(
                  right: i < categories.length - 1 ? 16 : 0,
                ),
                child: _FoodCategoryItem(cat: cat, imageSize: imageSize)
                    .animate(delay: Duration(milliseconds: 40 * i))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1, duration: 300.ms, curve: Curves.easeOutCubic),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodCategoryItem extends StatefulWidget {
  final AppFoodCategory cat;
  final double imageSize;
  const _FoodCategoryItem({required this.cat, required this.imageSize});

  @override
  State<_FoodCategoryItem> createState() => _FoodCategoryItemState();
}

class _FoodCategoryItemState extends State<_FoodCategoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.cat.onTap,
      child: ScaleTransition(
        scale: _ctrl,
        child: SizedBox(
          width: widget.imageSize,
          child: Column(
            children: [
              Container(
                width: widget.imageSize,
                height: widget.imageSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.cat.color ?? cs.primary).withOpacity(0.1),
                  border: Border.all(
                    color: (widget.cat.color ?? cs.primary).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.cat.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.cat.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: (widget.cat.color ?? cs.primary).withOpacity(0.08),
                        ),
                        errorWidget: (_, __, ___) => _CategoryIcon(cat: widget.cat),
                      )
                    : _CategoryIcon(cat: widget.cat),
              ),
              const SizedBox(height: 6),
              Text(
                widget.cat.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final AppFoodCategory cat;
  const _CategoryIcon({required this.cat});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(
      cat.icon ?? Iconsax.coffee,
      size: 30,
      color: cat.color ?? cs.primary,
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────
/// Zomato-style scrollable filter/sort chips (Sort, Rating, Nearest, etc.)
class AppFilterChip {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool hasDropdown;

  const AppFilterChip({
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.hasDropdown = false,
  });
}

class AppFilterBar extends StatefulWidget {
  final List<AppFilterChip> filters;
  final int? initialSelected;
  final ValueChanged<int?>? onSelected;
  final EdgeInsets padding;
  final bool showDivider;

  const AppFilterBar({
    super.key,
    required this.filters,
    this.initialSelected,
    this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.showDivider = false,
  });

  @override
  State<AppFilterBar> createState() => _AppFilterBarState();
}

class _AppFilterBarState extends State<AppFilterBar> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.filters.length,
            itemBuilder: (context, i) {
              final f = widget.filters[i];
              final selected = _selected == i;
              return Padding(
                padding: EdgeInsets.only(
                  right: i < widget.filters.length - 1 ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selected = selected ? null : i);
                    widget.onSelected?.call(selected ? null : i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : isDark
                              ? cs.surfaceContainerHighest
                              : cs.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: selected ? cs.primary : cs.outlineVariant,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (f.leadingIcon != null) ...[
                          Icon(
                            f.leadingIcon,
                            size: 14,
                            color: selected ? Colors.white : cs.onSurface,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          f.label,
                          style: TextStyle(
                            color: selected ? Colors.white : cs.onSurface,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        if (f.hasDropdown || f.trailingIcon != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            f.trailingIcon ?? Iconsax.arrow_down_1,
                            size: 16,
                            color: selected ? Colors.white : cs.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: 30 * i))
                    .fadeIn(duration: 250.ms)
                    .slideX(begin: 0.08, duration: 250.ms),
              );
            },
          ),
        ),
        if (widget.showDivider) Divider(height: 1, color: cs.outlineVariant),
      ],
    );
  }
}

/// Default Zomato-style filter set.
List<AppFilterChip> appDefaultFilters() => const [
  AppFilterChip(label: 'Sort', leadingIcon: Iconsax.sort, hasDropdown: true),
  AppFilterChip(label: 'Fastest Delivery', leadingIcon: Iconsax.flash),
  AppFilterChip(label: 'Rating 4.0+', leadingIcon: Iconsax.star),
  AppFilterChip(label: 'Pure Veg', leadingIcon: Iconsax.milk),
  AppFilterChip(label: 'Offers', leadingIcon: Iconsax.tag),
  AppFilterChip(label: 'New on App'),
  AppFilterChip(label: 'Less than ₹150'),
];

// ─── Location Header ──────────────────────────────────────────────────────────
/// Zomato-style top location header with city name and dropdown.
class AppLocationHeader extends StatelessWidget {
  final String city;
  final String? area;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppLocationHeader({
    super.key,
    required this.city,
    this.area,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Location icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.location, size: 18, color: cs.error),
          ),
          const SizedBox(width: 10),

          // City + area
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              area ?? city,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (onTap != null)
                              Icon(
                                Iconsax.arrow_down_1,
                                size: 18,
                                color: cs.onSurface,
                              ),
                          ],
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (area != null)
                          Text(
                            city,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trailing
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Offer Card ───────────────────────────────────────────────────────────────
/// Large percent-discount offer banner card.
class AppOfferCard extends StatelessWidget {
  final String discount; // "50% OFF"
  final String? upto; // "up to ₹100"
  final String? code; // "USE TRYNEW"
  final String? description;
  final List<Color> gradientColors;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppOfferCard({
    super.key,
    required this.discount,
    this.upto,
    this.code,
    this.description,
    this.gradientColors = const [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background circle
            Positioned(
              right: -16,
              bottom: -16,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Content
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon ?? Iconsax.tag,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            discount,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          if (upto != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              upto!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      if (code != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            code!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Divider with Label ───────────────────────────────────────────────
class AppSectionDivider extends StatelessWidget {
  final String? label;
  const AppSectionDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (label == null) {
      return Container(
        height: 8,
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        margin: const EdgeInsets.symmetric(vertical: 8),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: cs.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          Expanded(child: Divider(color: cs.outlineVariant)),
        ],
      ),
    );
  }
}

// ─── Top Search Bar ───────────────────────────────────────────────────────────
/// Zomato-style large search bar with location context.
class AppTopSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final String? location;
  final Widget? trailing;

  const AppTopSearchBar({
    super.key,
    this.hint = 'Search for restaurants and food',
    this.onTap,
    this.location,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 50,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Iconsax.search_normal, color: cs.onSurfaceVariant, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withOpacity(0.7),
                    ),
              ),
            ),
            if (trailing != null) trailing!
            else if (location != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.direct_right, size: 12, color: cs.primary),
                    const SizedBox(width: 3),
                    Text(
                      location!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
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

// ─── Default food categories ──────────────────────────────────────────────────
List<AppFoodCategory> appDefaultFoodCategories() => [
  const AppFoodCategory(label: 'Pizza', icon: Iconsax.coffee, color: Color(0xFFDC2626)),
  const AppFoodCategory(label: 'Burger', icon: Iconsax.coffee, color: Color(0xFFD97706)),
  const AppFoodCategory(label: 'Biryani', icon: Iconsax.cup, color: Color(0xFF7C3AED)),
  const AppFoodCategory(label: 'Chinese', icon: Iconsax.milk, color: Color(0xFF0891B2)),
  const AppFoodCategory(label: 'Desserts', icon: Iconsax.cake, color: Color(0xFFEC4899)),
  const AppFoodCategory(label: 'Salads', icon: Iconsax.milk, color: Color(0xFF16A34A)),
  const AppFoodCategory(label: 'North Indian', icon: Iconsax.cup, color: Color(0xFFD97706)),
  const AppFoodCategory(label: 'South Indian', icon: Iconsax.coffee, color: Color(0xFF2563EB)),
  const AppFoodCategory(label: 'Rolls & Wraps', icon: Iconsax.bank, color: Color(0xFF7C3AED)),
  const AppFoodCategory(label: 'Seafood', icon: Iconsax.cup, color: Color(0xFF0891B2)),
];
