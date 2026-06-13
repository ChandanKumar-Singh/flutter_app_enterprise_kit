// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/cards/app_restaurant_card.dart';
import 'package:enterprise_kit/shared/widgets/food/app_food_widgets.dart';
import 'package:enterprise_kit/shared/widgets/navigation/app_bottom_nav.dart';

class FoodShowcasePage extends StatefulWidget {
  const FoodShowcasePage({super.key});

  @override
  State<FoodShowcasePage> createState() => _FoodShowcasePageState();
}

class _FoodShowcasePageState extends State<FoodShowcasePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            floating: false,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0.5,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left_2, size: 18, color: cs.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
              title: Text(
                'Food & Restaurant UI',
                style: theme.textTheme.titleMedium?.copyWith(
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
                          const Color(0xFFDC2626).withOpacity(0.12),
                          const Color(0xFFD97706).withOpacity(0.08),
                          cs.surface,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20, top: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFDC2626).withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20, bottom: 50,
                    child: Text(
                      '🍕🍔🌮',
                      style: TextStyle(fontSize: 28, color: Colors.black.withOpacity(0.06)),
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: theme.textTheme.labelMedium,
              indicatorColor: cs.primary,
              dividerColor: cs.outlineVariant,
              tabs: const [
                Tab(text: 'Restaurant Cards'),
                Tab(text: 'Food Categories'),
                Tab(text: 'Filter & Search'),
                Tab(text: 'Offer Cards'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _RestaurantCardsTab(),
            _FoodCategoriesTab(),
            _FilterSearchTab(),
            _OfferCardsTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Restaurant Cards ──────────────────────────────────────────────────
class _RestaurantCardsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Vertical cards
          AppSectionHeader(
            title: 'Vertical Card',
            subtitle: 'Full card with hero image, rating, offers',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppRestaurantCard(
              name: 'The Spice Garden',
              rating: 4.5,
              ratingCount: 1200,
              deliveryTime: '25–30 min',
              deliveryFee: 'Free delivery',
              distance: '1.2 km',
              cuisines: const ['North Indian', 'Chinese', 'Biryani'],
              offers: const [
                AppRestaurantOffer('50% OFF up to ₹100', color: Color(0xFF1D4ED8)),
                AppRestaurantOffer('Free delivery on orders above ₹199'),
              ],
              promoLabel: '50% OFF up to ₹100',
              isPromoted: true,
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          ),

          const SizedBox(height: 20),
          AppSectionHeader(
            title: 'Closed Variant',
            subtitle: 'Shows closed overlay',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppRestaurantCard(
              name: 'Burger Junction',
              rating: 4.2,
              cuisines: const ['Burger', 'Wraps', 'Fast Food'],
              isClosed: true,
              closedMessage: 'Opens at 11:00 AM',
              onTap: () {},
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          ),

          const SizedBox(height: 20),
          AppSectionHeader(
            title: 'Horizontal Cards',
            subtitle: 'Compact row layout',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 10),
          ..._sampleRestaurants.take(4).toList().asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppRestaurantCard(
              name: e.value.name,
              rating: e.value.rating,
              deliveryTime: e.value.deliveryTime,
              cuisines: e.value.cuisines,
              style: AppRestaurantCardStyle.horizontal,
              onTap: () {},
            ).animate(delay: Duration(milliseconds: 50 * e.key)).fadeIn(duration: 280.ms).slideX(begin: 0.04),
          )),

          const SizedBox(height: 20),
          AppSectionHeader(
            title: 'Compact Grid',
            subtitle: '2-column compact layout',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _sampleRestaurants.take(4).toList().asMap().entries.map((e) =>
                AppRestaurantCard(
                  name: e.value.name,
                  rating: e.value.rating,
                  deliveryTime: e.value.deliveryTime,
                  cuisines: e.value.cuisines,
                  style: AppRestaurantCardStyle.compact,
                  onTap: () {},
                ).animate(delay: Duration(milliseconds: 60 * e.key)).fadeIn(duration: 300.ms)
              ).toList(),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Tab 2: Food Categories ───────────────────────────────────────────────────
class _FoodCategoriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Location header
          AppSectionHeader(
            title: 'Location Header',
            subtitle: 'City + area with dropdown',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: AppLocationHeader(
              city: 'Bangalore',
              area: 'Indiranagar',
              subtitle: 'Karnataka 560038',
              onTap: () {},
              trailing: IconButton(
                icon: Icon(Iconsax.notification, color: cs.onSurface, size: 22),
                onPressed: () {},
              ),
            ),
          ).animate().fadeIn(delay: 50.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // Food categories default
          AppSectionHeader(
            title: 'Food Category Wheel',
            subtitle: '"What\'s on your mind?" — default categories',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 10),
          AppFoodCategoryWheel(
            categories: appDefaultFoodCategories(),
            showTitle: false,
          ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

          const SizedBox(height: 20),

          // Full with title
          AppSectionHeader(
            title: 'With Branded Title',
            subtitle: 'Custom imageSize: 80',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 4),
          AppFoodCategoryWheel(
            categories: appDefaultFoodCategories().take(6).toList(),
            imageSize: 80,
            title: "What's on your mind?",
          ).animate().fadeIn(delay: 250.ms, duration: 350.ms),

          const SizedBox(height: 24),

          // Section divider variants
          AppSectionHeader(
            title: 'Section Dividers',
            subtitle: 'Visual separators for sections',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          const AppSectionDivider(),
          const AppSectionDivider(label: 'OR EXPLORE'),
          const AppSectionDivider(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Tab 3: Filter & Search ───────────────────────────────────────────────────
class _FilterSearchTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Search bar
          AppSectionHeader(
            title: 'Top Search Bar',
            subtitle: 'Full-width search with location context',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 8),
          AppTopSearchBar(
            hint: 'Search restaurants, dishes...',
            location: '1.2 km',
            onTap: () {},
          ).animate().fadeIn(delay: 50.ms, duration: 300.ms),

          const SizedBox(height: 8),
          AppTopSearchBar(
            hint: 'pizza, biryani, burger...',
            onTap: () {},
            trailing: Icon(Iconsax.microphone, color: cs.primary, size: 20),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // Filter bar
          AppSectionHeader(
            title: 'Filter Bar',
            subtitle: 'Scrollable filter chips — single select',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 4),
          AppFilterBar(
            filters: appDefaultFilters(),
            showDivider: true,
            onSelected: (_) {},
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: 20),
          AppSectionHeader(
            title: 'Custom Filters',
            subtitle: 'With dropdown arrows and initial selection',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 4),
          AppFilterBar(
            initialSelected: 0,
            filters: const [
              AppFilterChip(label: 'Recommended', hasDropdown: true),
              AppFilterChip(label: 'Nearest First', leadingIcon: Iconsax.location),
              AppFilterChip(label: 'Rating', leadingIcon: Iconsax.star),
              AppFilterChip(label: '₹ Low to High', leadingIcon: Iconsax.wallet_money),
              AppFilterChip(label: 'New', leadingIcon: Iconsax.flash),
            ],
            onSelected: (_) {},
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // Restaurant list after filter
          AppSectionHeader(
            title: 'Restaurant Feed',
            subtitle: 'Full vertical list with staggered entrance',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 10),
          AppRestaurantList(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            restaurants: _sampleRestaurants.take(3).map((r) => AppRestaurantCardData(
              name: r.name,
              rating: r.rating,
              deliveryTime: r.deliveryTime,
              deliveryFee: r.deliveryFee,
              distance: r.distance,
              cuisines: r.cuisines,
              offers: r.offers,
              promoLabel: r.promoLabel,
            )).toList(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Tab 4: Offer Cards ───────────────────────────────────────────────────────
class _OfferCardsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          AppSectionHeader(
            title: 'Offer Cards',
            subtitle: 'Discount banners with gradient backgrounds',
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),

          ..._offerCards.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: e.value
                .animate(delay: Duration(milliseconds: 80 * e.key))
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.05, duration: 300.ms),
          )),

          const SizedBox(height: 24),

          AppSectionHeader(
            title: 'Offer Row',
            subtitle: '2-column offer grid',
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: AppOfferCard(
                  discount: '60% OFF',
                  upto: 'up to ₹120',
                  code: 'WELCOME60',
                  gradientColors: const [Color(0xFFDC2626), Color(0xFFD97706)],
                  icon: Iconsax.award,
                  onTap: () {},
                ).animate(delay: 450.ms).fadeIn(duration: 300.ms),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppOfferCard(
                  discount: '₹0',
                  upto: 'delivery',
                  code: 'FREEDEL',
                  description: 'On first 5 orders',
                  gradientColors: const [Color(0xFF16A34A), Color(0xFF0891B2)],
                  icon: Iconsax.truck,
                  onTap: () {},
                ).animate(delay: 500.ms).fadeIn(duration: 300.ms),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Sample Data ──────────────────────────────────────────────────────────────
final _sampleRestaurants = [
  _RestaurantSample(
    name: 'The Spice Garden',
    rating: 4.5,
    deliveryTime: '25–30 min',
    deliveryFee: 'Free delivery',
    distance: '1.2 km',
    cuisines: ['North Indian', 'Chinese'],
    offers: [const AppRestaurantOffer('50% OFF up to ₹100', color: Color(0xFF1D4ED8))],
    promoLabel: '50% OFF up to ₹100',
  ),
  _RestaurantSample(
    name: 'Burger Junction',
    rating: 4.2,
    deliveryTime: '20–25 min',
    deliveryFee: '₹29 delivery',
    distance: '0.8 km',
    cuisines: ['Burger', 'Wraps'],
    offers: [const AppRestaurantOffer('Buy 1 Get 1 Free')],
    promoLabel: 'BOGO Deal',
  ),
  _RestaurantSample(
    name: 'Dosa Delight',
    rating: 4.7,
    deliveryTime: '30–35 min',
    deliveryFee: 'Free delivery',
    distance: '2.1 km',
    cuisines: ['South Indian', 'Breakfast'],
    offers: [],
  ),
  _RestaurantSample(
    name: 'Pizza Paradise',
    rating: 4.3,
    deliveryTime: '35–40 min',
    deliveryFee: '₹49 delivery',
    distance: '3.5 km',
    cuisines: ['Pizza', 'Italian', 'Pasta'],
    offers: [const AppRestaurantOffer('20% OFF on Large Pizza')],
    promoLabel: '20% OFF',
  ),
  _RestaurantSample(
    name: 'Biryani Bowl',
    rating: 4.6,
    deliveryTime: '40–45 min',
    deliveryFee: 'Free delivery',
    distance: '1.8 km',
    cuisines: ['Biryani', 'Mughlai'],
    offers: [const AppRestaurantOffer('Flat ₹150 OFF', color: Color(0xFF7C3AED))],
    promoLabel: 'Flat ₹150 OFF',
  ),
];

class _RestaurantSample {
  final String name;
  final double rating;
  final String deliveryTime;
  final String deliveryFee;
  final String distance;
  final List<String> cuisines;
  final List<AppRestaurantOffer> offers;
  final String? promoLabel;
  const _RestaurantSample({
    required this.name,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.distance,
    required this.cuisines,
    required this.offers,
    this.promoLabel,
  });
}

final _offerCards = [
  AppOfferCard(
    discount: '50% OFF',
    upto: 'up to ₹100',
    code: 'TRYNEW',
    description: 'Valid on your first order',
    gradientColors: const [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
    icon: Iconsax.tag,
    onTap: () {},
  ),
  AppOfferCard(
    discount: 'Free\nDelivery',
    upto: 'on all orders',
    code: 'FREEDEL',
    gradientColors: const [Color(0xFF16A34A), Color(0xFF0891B2)],
    icon: Iconsax.truck,
    onTap: () {},
  ),
  AppOfferCard(
    discount: '30% OFF',
    upto: 'up to ₹75',
    code: 'WEEKEND',
    description: 'Weekend special offer',
    gradientColors: const [Color(0xFFD97706), Color(0xFFDC2626)],
    icon: Iconsax.award,
    onTap: () {},
  ),
  AppOfferCard(
    discount: '₹200 OFF',
    upto: 'on orders ₹599+',
    code: 'SAVE200',
    gradientColors: const [Color(0xFF7C3AED), Color(0xFFEC4899)],
    icon: Iconsax.wallet,
    onTap: () {},
  ),
];
