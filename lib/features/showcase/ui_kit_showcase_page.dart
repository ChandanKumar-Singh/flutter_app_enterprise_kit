// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/banners/app_promo_banner.dart';
import 'package:enterprise_kit/shared/widgets/cards/app_product_card.dart';
import 'package:enterprise_kit/shared/widgets/navigation/app_bottom_nav.dart';

class UiKitShowcasePage extends StatefulWidget {
  const UiKitShowcasePage({super.key});

  @override
  State<UiKitShowcasePage> createState() => _UiKitShowcasePageState();
}

class _UiKitShowcasePageState extends State<UiKitShowcasePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Cart state demo
  final Map<int, int> _cart = {};
  final Map<int, bool> _favorites = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Kit Showcase'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Product Cards'),
            Tab(text: 'Feature Cards'),
            Tab(text: 'Promo Banners'),
            Tab(text: 'Navigation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ProductCardsTab(cart: _cart, favorites: _favorites, onCartChange: (id, qty) {
            setState(() => _cart[id] = qty);
          }, onFavToggle: (id) {
            setState(() => _favorites[id] = !(_favorites[id] ?? false));
          }),
          const _FeatureCardsTab(),
          const _PromoBannerTab(),
          const _NavigationTab(),
        ],
      ),
    );
  }
}

// ─── Product Cards Tab ────────────────────────────────────────────────────────
class _ProductCardsTab extends StatelessWidget {
  final Map<int, int> cart;
  final Map<int, bool> favorites;
  final void Function(int id, int qty) onCartChange;
  final void Function(int id) onFavToggle;

  const _ProductCardsTab({
    required this.cart,
    required this.favorites,
    required this.onCartChange,
    required this.onFavToggle,
  });

  static final _products = [
    _Product(1, 'Butter Chicken', 'Restaurant-style', 349, 499, 30, 4.5, 2842, 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400'),
    _Product(2, 'Masala Dosa', 'Crispy, authentic', 129, 179, 28, 4.7, 5621, 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'),
    _Product(3, 'Veg Biryani', 'Dum-cooked rice', 229, 299, 23, 4.3, 1923, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400'),
    _Product(4, 'Mango Lassi', 'Fresh & chilled', 99, 129, 23, 4.8, 8901, 'https://images.unsplash.com/photo-1553361371-9b22f78e8b1d?w=400'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Label('Grid — Vertical cards'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _products.length,
          itemBuilder: (_, i) {
            final p = _products[i];
            final qty = cart[p.id] ?? 0;
            return AppProductCard(
              title: p.title,
              subtitle: p.subtitle,
              imageUrl: p.imageUrl,
              price: p.price,
              originalPrice: p.originalPrice,
              discountPercent: p.discountPercent,
              rating: p.rating,
              reviewCount: p.reviewCount,
              isFavorite: favorites[p.id] ?? false,
              inCart: qty > 0,
              cartQuantity: qty,
              heroTag: 'product_${p.id}',
              size: AppProductCardSize.medium,
              onFavoriteToggle: () => onFavToggle(p.id),
              onAdd: () => onCartChange(p.id, qty + 1),
              onRemove: () => onCartChange(p.id, (qty - 1).clamp(0, 99)),
              onTap: () {},
            ).animate(delay: Duration(milliseconds: 50 * i))
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
          },
        ),

        const SizedBox(height: 20),
        _Label('Horizontal cards'),
        const SizedBox(height: 10),
        ..._products.take(3).map((p) {
          final qty = cart[p.id] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppProductCard(
              title: p.title,
              subtitle: p.subtitle,
              imageUrl: p.imageUrl,
              price: p.price,
              originalPrice: p.originalPrice,
              rating: p.rating,
              inCart: qty > 0,
              cartQuantity: qty,
              size: AppProductCardSize.horizontal,
              onAdd: () => onCartChange(p.id, qty + 1),
              onRemove: () => onCartChange(p.id, (qty - 1).clamp(0, 99)),
              onTap: () {},
            ).animate().fadeIn(duration: 300.ms),
          );
        }),

        const SizedBox(height: 20),
        _Label('Stat Cards'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            AppStatCard(label: 'Revenue', value: '₹2.4M', trend: '+18%', trendUp: true, icon: Icons.currency_rupee_rounded, color: const Color(0xFF16A34A)),
            AppStatCard(label: 'Orders', value: '8,291', trend: '+5.2%', trendUp: true, icon: Icons.shopping_bag_rounded, color: const Color(0xFF2563EB)),
            AppStatCard(label: 'Returns', value: '142', trend: '-3%', trendUp: false, icon: Icons.replay_rounded, color: const Color(0xFFDC2626)),
            AppStatCard(label: 'Rating', value: '4.7★', subValue: '12,490 reviews', icon: Icons.star_rounded, color: const Color(0xFFF59E0B)),
          ],
        ),

        const SizedBox(height: 20),
        _Label('Category Chips'),
        const SizedBox(height: 10),
        _CategoryChipsDemo(),
      ],
    );
  }
}

class _Product {
  final int id;
  final String title;
  final String subtitle;
  final double price;
  final double originalPrice;
  final double discountPercent;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  const _Product(this.id, this.title, this.subtitle, this.price, this.originalPrice, this.discountPercent, this.rating, this.reviewCount, this.imageUrl);
}

class _CategoryChipsDemo extends StatefulWidget {
  @override
  State<_CategoryChipsDemo> createState() => _CategoryChipsDemoState();
}

class _CategoryChipsDemoState extends State<_CategoryChipsDemo> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final categories = [
      (Icons.restaurant_rounded, 'All'),
      (Icons.local_pizza_rounded, 'Fast Food'),
      (Icons.rice_bowl_rounded, 'Indian'),
      (Icons.local_cafe_rounded, 'Beverages'),
      (Icons.cake_rounded, 'Desserts'),
      (Icons.local_pizza_rounded, 'Italian'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.asMap().entries.map((e) {
          final i = e.key;
          final (icon, label) = e.value;
          return Padding(
            padding: EdgeInsets.only(right: i < categories.length - 1 ? 8 : 0),
            child: AppCategoryChip(
              label: label,
              icon: icon,
              selected: _selected == i,
              onTap: () => setState(() => _selected = i),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Feature Cards Tab ────────────────────────────────────────────────────────
class _FeatureCardsTab extends StatelessWidget {
  const _FeatureCardsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Label('Full-width Feature Cards'),
        const SizedBox(height: 10),
        AppFeatureCard(
          title: 'Free delivery\non your first 5 orders',
          subtitle: 'LIMITED TIME OFFER',
          description: 'Get free delivery every time. No minimum order value.',
          gradientColors: const [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: const Text('Order Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1D4ED8))),
          ),
          onTap: () {},
          tags: const ['Free Delivery', '5 Orders'],
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),
        const SizedBox(height: 12),
        AppFeatureCard(
          title: '10-minute delivery\nin your area',
          subtitle: 'ZEPTO EXPRESS',
          description: 'Groceries, snacks, drinks & more at your door.',
          gradientColors: const [Color(0xFF7C3AED), Color(0xFFEC4899)],
          height: 160,
          onTap: () {},
          tags: const ['10 min', 'Grocery'],
        ).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppFeatureCard(
                title: 'Flat 30%\nOFF',
                subtitle: 'WEEKEND DEAL',
                gradientColors: const [Color(0xFFD97706), Color(0xFFDC2626)],
                height: 130,
                onTap: () {},
              ).animate(delay: 200.ms).fadeIn(duration: 350.ms),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppFeatureCard(
                title: 'Buy 2 Get\n1 Free',
                subtitle: 'TODAY ONLY',
                gradientColors: const [Color(0xFF16A34A), Color(0xFF0891B2)],
                height: 130,
                onTap: () {},
              ).animate(delay: 250.ms).fadeIn(duration: 350.ms),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Label('Category Chips'),
        const SizedBox(height: 10),
        _CategoriesGrid(),
      ],
    );
  }
}

class _CategoriesGrid extends StatefulWidget {
  @override
  State<_CategoriesGrid> createState() => _CategoriesGridState();
}

class _CategoriesGridState extends State<_CategoriesGrid> {
  int _sel = 0;
  final _cats = [
    ('Home', Icons.home_rounded, const Color(0xFF2563EB)),
    ('Food', Icons.restaurant_rounded, const Color(0xFFDC2626)),
    ('Health', Icons.health_and_safety_rounded, const Color(0xFF16A34A)),
    ('Style', Icons.shopping_bag_rounded, const Color(0xFF7C3AED)),
    ('Finance', Icons.account_balance_rounded, const Color(0xFF0891B2)),
    ('Travel', Icons.flight_rounded, const Color(0xFFD97706)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cats.asMap().entries.map((e) {
        final i = e.key;
        final (label, icon, color) = e.value;
        return AppCategoryChip(
          label: label,
          icon: icon,
          color: color,
          selected: _sel == i,
          onTap: () => setState(() => _sel = i),
        ).animate(delay: Duration(milliseconds: 40 * i))
         .scale(begin: const Offset(0.7, 0.7), duration: 350.ms, curve: Curves.elasticOut)
         .fadeIn(duration: 250.ms);
      }).toList(),
    );
  }
}

// ─── Promo Banner Tab ─────────────────────────────────────────────────────────
class _PromoBannerTab extends StatelessWidget {
  const _PromoBannerTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Label('Auto-scrolling Promo Carousel'),
        const SizedBox(height: 10),
        AppPromoBanner(
          height: 165,
          items: const [
            AppPromoBannerItem(
              title: 'Flat 50% OFF\non electronics',
              subtitle: 'MEGA SALE',
              ctaLabel: 'Shop Now',
              gradientColors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
            ),
            AppPromoBannerItem(
              title: 'Free delivery\nthis weekend',
              subtitle: 'WEEKEND OFFER',
              ctaLabel: 'Order Now',
              gradientColors: [Color(0xFF16A34A), Color(0xFF0891B2)],
            ),
            AppPromoBannerItem(
              title: 'Buy 2 Get 1\nFree on fashion',
              subtitle: 'TRENDING NOW',
              ctaLabel: 'Explore',
              gradientColors: [Color(0xFFD97706), Color(0xFFDC2626)],
            ),
            AppPromoBannerItem(
              title: 'New arrivals\nevery Friday',
              subtitle: 'JUST IN',
              ctaLabel: 'See What\'s New',
              gradientColors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
            ),
          ],
        ).animate().fadeIn(duration: 350.ms),

        const SizedBox(height: 20),
        _Label('Trust/USP Info Strip'),
        const SizedBox(height: 10),
        appInfoStripDefault().animate().fadeIn(delay: 100.ms, duration: 350.ms),

        const SizedBox(height: 20),
        _Label('Single Promo Cards'),
        const SizedBox(height: 10),
        AppPromoBanner(
          height: 130,
          autoPlay: false,
          showIndicator: false,
          margin: EdgeInsets.zero,
          items: const [
            AppPromoBannerItem(
              title: 'Flash Sale\nEnds in 2:00:00',
              subtitle: 'HURRY UP',
              ctaLabel: 'Grab Deals',
              gradientColors: [Color(0xFFDC2626), Color(0xFFD97706)],
            ),
          ],
        ).animate(delay: 200.ms).fadeIn(duration: 350.ms),

        const SizedBox(height: 12),
        AppPromoBanner(
          height: 130,
          autoPlay: false,
          showIndicator: false,
          margin: EdgeInsets.zero,
          items: const [
            AppPromoBannerItem(
              title: 'Refer & Earn\n₹100 per referral',
              subtitle: 'REWARD PROGRAM',
              ctaLabel: 'Invite Friends',
              gradientColors: [Color(0xFF0891B2), Color(0xFF16A34A)],
            ),
          ],
        ).animate(delay: 300.ms).fadeIn(duration: 350.ms),
      ],
    );
  }
}

// ─── Navigation Tab ───────────────────────────────────────────────────────────
class _NavigationTab extends StatefulWidget {
  const _NavigationTab();

  @override
  State<_NavigationTab> createState() => _NavigationTabState();
}

class _NavigationTabState extends State<_NavigationTab> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Label('Floating Glassmorphism Bottom Nav'),
            const SizedBox(height: 10),
            Text(
              'Tap the nav items below to see transitions. The floating nav sits above the content with blur and shadow effects.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _Label('Section Headers'),
            const SizedBox(height: 10),
            AppSectionHeader(
              title: 'Recommended For You',
              subtitle: '12 items',
              actionLabel: 'See All',
              onAction: () {},
              leading: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.recommend_rounded, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            const Divider(),
            AppSectionHeader(
              title: 'Trending Now',
              subtitle: 'Updated hourly',
              actionLabel: 'View More',
              onAction: () {},
            ),
            const Divider(),
            AppSectionHeader(
              title: 'Recently Viewed',
              onAction: () {},
              actionLabel: 'Clear History',
            ),
            const SizedBox(height: 120),
          ],
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: AppFloatingBottomNav(
            currentIndex: _navIndex,
            onIndexChanged: (i) => setState(() => _navIndex = i),
            items: const [
              AppBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
              AppBottomNavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Search'),
              AppBottomNavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Cart', badgeCount: 3),
              AppBottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
            ],
          ).animate().slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.primary,
        letterSpacing: 0.2,
      ),
    );
  }
}
