// ─── ServicesShowcasePage ─────────────────────────────────────────────────────
// Live demos for all Sprint 2 services & components.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:enterprise_kit/core/notifications/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/core/feature_flags/app_feature_flags.dart';
import 'package:enterprise_kit/core/auth/app_biometric_auth_service.dart';
import 'package:enterprise_kit/core/storage/app_encrypted_storage.dart';
import 'package:enterprise_kit/core/data/app_cache_manager.dart';
import 'package:enterprise_kit/core/notifications/app_notification_service.dart';
import 'package:enterprise_kit/core/notifications/app_notification_payload.dart';
import 'package:enterprise_kit/core/update/app_update_service.dart';
import 'package:enterprise_kit/shared/widgets/wizard/app_wizard.dart';
import 'package:enterprise_kit/shared/widgets/search/app_search_overlay.dart';
import 'package:enterprise_kit/shared/widgets/charts/app_charts.dart';
import 'package:enterprise_kit/core/toast/app_toast.dart';

class ServicesShowcasePage extends StatefulWidget {
  const ServicesShowcasePage({super.key});

  @override
  State<ServicesShowcasePage> createState() => _ServicesShowcasePageState();
}

class _ServicesShowcasePageState extends State<ServicesShowcasePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _tabs = [
    (icon: Icons.notifications_rounded,  label: 'Notifications'),
    (icon: Icons.flag_rounded,           label: 'Flags'),
    (icon: Icons.fingerprint_rounded,    label: 'Biometric'),
    (icon: Icons.lock_rounded,           label: 'Enc Storage'),
    (icon: Icons.storage_rounded,        label: 'Cache'),
    (icon: Icons.linear_scale_rounded,   label: 'Wizard'),
    (icon: Icons.search_rounded,         label: 'Search'),
    (icon: Icons.bar_chart_rounded,      label: 'Charts'),
    (icon: Icons.system_update_rounded,  label: 'Updates'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services & Components'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(
            icon: Icon(t.icon, size: 18),
            text: t.label,
            iconMargin: const EdgeInsets.only(bottom: 2),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _NotificationsTab(),
          _FeatureFlagsTab(),
          _BiometricTab(),
          _EncStorageTab(),
          _CacheTab(),
          _WizardTab(),
          _SearchTab(),
          _ChartsTab(),
          _UpdateCheckerTab(),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _DemoSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _DemoSection({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DemoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _DemoButton({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (color ?? cs.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: color ?? cs.primary, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        tileColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
    );
  }
}

void _showResult(BuildContext context, String message) {
  AppToastController.instance.info(message);
}

// ── Notifications Tab ─────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        _DemoSection(
          title: 'AppNotificationService',
          subtitle: 'flutter_local_notifications with channel routing',
          icon: Icons.notifications_rounded,
          color: const Color(0xFF7C3AED),
          children: [
            _DemoButton(
              label: 'Request Permission',
              icon: Icons.security_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () async {
                final granted =
                    await AppNotificationService.instance.requestPermission();
                if (context.mounted) {
                  _showResult(context, granted
                      ? 'Permission granted ✓'
                      : 'Permission denied');
                }
              },
            ),
            _DemoButton(
              label: 'Show Order Notification',
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFF16A34A),
              onTap: () => AppNotificationService.instance.show(
                id: AppNotificationId.orderUpdate,
                title: 'Order Shipped! 📦',
                body: 'Your order #ORD-2847 is on the way.',
                channel: AppNotificationChannel.orders,
                payload: AppNotificationPayload.route('/orders/2847'),
              ),
            ),
            _DemoButton(
              label: 'Show Promo Notification',
              icon: Icons.local_offer_rounded,
              color: const Color(0xFFD97706),
              onTap: () => AppNotificationService.instance.show(
                id: AppNotificationId.promoAlert,
                title: '🎉 Flash Sale – 50% Off!',
                body: 'Hurry! Offer ends in 2 hours.',
                channel: AppNotificationChannel.promotions,
              ),
            ),
            _DemoButton(
              label: 'Cancel All Notifications',
              icon: Icons.clear_all_rounded,
              color: const Color(0xFFDC2626),
              onTap: () async {
                await AppNotificationService.instance.cancelAll();
                if (context.mounted) _showResult(context, 'All notifications cancelled');
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ── Feature Flags Tab ─────────────────────────────────────────────────────────

// Demo flags for the showcase
const _demoNewCheckout = AppBoolFlag('demo_new_checkout', defaultValue: false);
const _demoMaxItems    = AppIntFlag('demo_max_items',    defaultValue: 5);
const _demoBannerText  = AppStringFlag('demo_banner',    defaultValue: 'Welcome back!');

class _FeatureFlagsTab extends StatefulWidget {
  const _FeatureFlagsTab();

  @override
  State<_FeatureFlagsTab> createState() => _FeatureFlagsTabState();
}

class _FeatureFlagsTabState extends State<_FeatureFlagsTab> {
  bool _newCheckout = false;
  int _maxItems = 5;

  @override
  void initState() {
    super.initState();
    _newCheckout = _demoNewCheckout.cachedValue;
    _maxItems    = _demoMaxItems.cachedValue;
    AppFeatureFlags.instance.addListener(_onFlagsChanged);
  }

  void _onFlagsChanged() {
    setState(() {
      _newCheckout = _demoNewCheckout.cachedValue;
      _maxItems    = _demoMaxItems.cachedValue;
    });
  }

  @override
  void dispose() {
    AppFeatureFlags.instance.removeListener(_onFlagsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _DemoSection(
          title: 'AppFeatureFlags',
          subtitle: 'Type-safe toggle system with override support',
          icon: Icons.flag_rounded,
          color: const Color(0xFF0891B2),
          children: [
            // Live toggle
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Overrides',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      title: const Text('New Checkout Flow'),
                      subtitle: Text(
                        'Flag: demo_new_checkout = $_newCheckout',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                      value: _newCheckout,
                      onChanged: (v) {
                        AppFeatureFlags.instance.setOverride(_demoNewCheckout, v);
                      },
                    ),
                    ListTile(
                      title: const Text('Max Items in Cart'),
                      subtitle: Text(
                        'demo_max_items = $_maxItems',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded),
                            onPressed: () => AppFeatureFlags.instance
                                .setOverride(_demoMaxItems, (_maxItems - 1).clamp(1, 20)),
                          ),
                          Text('$_maxItems',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              )),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () => AppFeatureFlags.instance
                                .setOverride(_demoMaxItems, (_maxItems + 1).clamp(1, 20)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    TextButton.icon(
                      onPressed: () {
                        AppFeatureFlags.instance.clearAllOverrides();
                        _showResult(context, 'All overrides cleared');
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Clear all overrides'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Biometric Tab ─────────────────────────────────────────────────────────────

class _BiometricTab extends StatelessWidget {
  const _BiometricTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        _DemoSection(
          title: 'AppBiometricAuthService',
          subtitle: 'Fingerprint / Face ID with session locking',
          icon: Icons.fingerprint_rounded,
          color: const Color(0xFF7C3AED),
          children: [
            _DemoButton(
              label: 'Check Availability',
              icon: Icons.info_rounded,
              onTap: () async {
                final cap =
                    await AppBiometricAuthService.instance.getCapability();
                if (context.mounted) {
                  _showResult(context, cap.isAvailable
                      ? '${cap.displayName} available ✓'
                      : 'Biometrics not available');
                }
              },
            ),
            _DemoButton(
              label: 'Authenticate',
              icon: Icons.fingerprint_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () async {
                final result =
                    await AppBiometricAuthService.instance.authenticate(
                  reason: 'Confirm your identity',
                );
                if (context.mounted) {
                  _showResult(context, switch (result) {
                    AppAuthSuccess()     => 'Authentication successful ✓',
                    AppAuthFailure f     => 'Failed: ${f.reason}',
                    AppAuthCancelled()   => 'Cancelled',
                    AppAuthNotAvailable() => 'Not available on this device',
                  });
                }
              },
            ),
            _DemoButton(
              label: 'Show Lock Screen',
              icon: Icons.lock_rounded,
              color: const Color(0xFF0891B2),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AppBiometricLockScreen(
                    onUnlock: () async {
                      final result =
                          await AppBiometricAuthService.instance.authenticate(
                        reason: 'Unlock to continue',
                      );
                      if (result is AppAuthSuccess && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ));
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ── Encrypted Storage Tab ─────────────────────────────────────────────────────

class _EncStorageTab extends StatefulWidget {
  const _EncStorageTab();

  @override
  State<_EncStorageTab> createState() => _EncStorageTabState();
}

class _EncStorageTabState extends State<_EncStorageTab> {
  String? _readValue;
  final _keyCtrl = TextEditingController(text: 'demo_secret');
  final _valCtrl = TextEditingController(text: 'Hello Encrypted World!');

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _DemoSection(
          title: 'AppEncryptedStorage',
          subtitle: 'AES-256 GCM encrypted SharedPreferences',
          icon: Icons.lock_rounded,
          color: const Color(0xFF16A34A),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  TextField(
                    controller: _keyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Key',
                      prefixIcon: Icon(Icons.key_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _valCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Value (plaintext)',
                      prefixIcon: Icon(Icons.text_fields_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await AppEncryptedStorage.instance
                                .setString(_keyCtrl.text, _valCtrl.text);
                            if (context.mounted) {
                              _showResult(context, 'Encrypted & saved ✓');
                            }
                          },
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Encrypt & Save'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final val = await AppEncryptedStorage.instance
                                .getString(_keyCtrl.text);
                            setState(() => _readValue = val ?? '(not found)');
                          },
                          icon: const Icon(Icons.lock_open_rounded, size: 16),
                          label: const Text('Decrypt & Read'),
                        ),
                      ),
                    ],
                  ),
                  if (_readValue != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: cs.primary, size: 16),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _readValue!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Cache Tab ─────────────────────────────────────────────────────────────────

class _CacheTab extends StatefulWidget {
  const _CacheTab();

  @override
  State<_CacheTab> createState() => _CacheTabState();
}

class _CacheTabState extends State<_CacheTab> {
  AppCacheStats? _stats;

  void _refresh() =>
      setState(() => _stats = AppCacheManager.instance.stats);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final stats = _stats;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _DemoSection(
          title: 'AppCacheManager',
          subtitle: 'L1 memory + L2 persistent cache with TTL',
          icon: Icons.storage_rounded,
          color: const Color(0xFFD97706),
          children: [
            if (stats != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cache Statistics',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.sm),
                        _StatRow('Memory entries', '${stats.memoryEntries}'),
                        _StatRow('Disk entries', '${stats.persistentEntries}'),
                        _StatRow('Cache hits', '${stats.hits}'),
                        _StatRow('Cache misses', '${stats.misses}'),
                        _StatRow('Hit rate',
                            '${(stats.hitRate * 100).toStringAsFixed(1)}%'),
                        _StatRow('Evictions', '${stats.evictions}'),
                      ],
                    ),
                  ),
                ),
              ),
            _DemoButton(
              label: 'Cache a value (5s TTL)',
              icon: Icons.add_rounded,
              color: const Color(0xFF16A34A),
              onTap: () async {
                await AppCacheManager.instance.set(
                  'demo/showcase',
                  {'timestamp': DateTime.now().toIso8601String()},
                  ttl: const Duration(seconds: 5),
                );
                _refresh();
                if (context.mounted) {
                  _showResult(context, 'Cached for 5 seconds');
                }
              },
            ),
            _DemoButton(
              label: 'Read cached value',
              icon: Icons.read_more_rounded,
              onTap: () async {
                final val = await AppCacheManager.instance.get('demo/showcase');
                _refresh();
                if (context.mounted) {
                  _showResult(context,
                      val != null ? 'Hit: $val' : 'Miss (expired or not set)');
                }
              },
            ),
            _DemoButton(
              label: 'Clear all cache',
              icon: Icons.delete_sweep_rounded,
              color: const Color(0xFFDC2626),
              onTap: () async {
                await AppCacheManager.instance.clearAll();
                _refresh();
                if (context.mounted) _showResult(context, 'Cache cleared');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Wizard Tab ────────────────────────────────────────────────────────────────

class _WizardTab extends StatelessWidget {
  const _WizardTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        _DemoSection(
          title: 'AppWizardFlow',
          subtitle: 'Multi-step progressive disclosure',
          icon: Icons.linear_scale_rounded,
          color: const Color(0xFF7C3AED),
          children: [
            _DemoButton(
              label: 'Open 3-Step Wizard',
              icon: Icons.open_in_new_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AppWizardPage(
                    title: 'Setup',
                    onCompleted: () {
                      Navigator.of(context).pop();
                      AppToastController.instance.success(
                        'Wizard completed!',
                        title: 'Done',
                      );
                    },
                    steps: [
                      AppWizardStep(
                        title: 'Welcome',
                        subtitle: 'Let\'s get you set up in just a few steps.',
                        icon: Icons.waving_hand_rounded,
                        builder: (_, ctrl) => const _WizardStep1(),
                      ),
                      AppWizardStep(
                        title: 'Your Preferences',
                        subtitle: 'Customise your experience.',
                        icon: Icons.tune_rounded,
                        canSkip: true,
                        builder: (_, ctrl) => const _WizardStep2(),
                      ),
                      AppWizardStep(
                        title: 'All Set!',
                        subtitle: 'You\'re ready to go.',
                        icon: Icons.check_circle_rounded,
                        nextLabel: 'Get Started',
                        canGoBack: false,
                        builder: (_, ctrl) => const _WizardStep3(),
                      ),
                    ],
                  ),
                ));
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _WizardStep1 extends StatelessWidget {
  const _WizardStep1();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text('Step 1 content goes here.\nForms, fields, onboarding info.'),
      ),
    );
  }
}

class _WizardStep2 extends StatelessWidget {
  const _WizardStep2();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text('Step 2: preferences, toggles, selections.'),
      ),
    );
  }
}

class _WizardStep3 extends StatelessWidget {
  const _WizardStep3();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, size: 80, color: cs.primary),
          const SizedBox(height: AppSpacing.lg),
          Text('All done!',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Search Tab ────────────────────────────────────────────────────────────────

class _DemoSearchDelegate extends AppSearchDelegate<String> {
  @override
  String get hintText => 'Search products, orders, users...';

  @override
  String get historyKey => 'showcase_search_history';

  @override
  Future<List<AppSearchResult<String>>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final all = [
      'iPhone 15 Pro Max', 'Samsung Galaxy S24', 'MacBook Air M3',
      'iPad Pro 2024', 'AirPods Pro', 'Apple Watch Series 9',
      'Sony WH-1000XM5', 'Dell XPS 13', 'LG OLED TV 65"',
      'OnePlus 12', 'Pixel 8 Pro', 'Surface Laptop 5',
    ];
    return all
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .map((s) => AppSearchResult(
              title: s,
              subtitle: 'Electronics',
              icon: Icons.shopping_bag_rounded,
              data: s,
            ))
        .toList();
  }

  @override
  Future<List<AppSearchResult<String>>> suggestions() async {
    return [
      const AppSearchResult(
        title: 'iPhone 15 Pro', subtitle: 'Trending', icon: Icons.trending_up_rounded),
      const AppSearchResult(
        title: 'MacBook Air', subtitle: 'Popular', icon: Icons.laptop_rounded),
    ];
  }

  @override
  void onResultTap(BuildContext context, AppSearchResult<String> result) {
    AppToastController.instance.info('Opened: ${result.title}');
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        _DemoSection(
          title: 'AppSearchOverlay',
          subtitle: 'Debounced full-screen search with history',
          icon: Icons.search_rounded,
          color: const Color(0xFF0891B2),
          children: [
            _DemoButton(
              label: 'Open Search Overlay',
              icon: Icons.search_rounded,
              color: const Color(0xFF0891B2),
              onTap: () => AppSearchOverlay.show(
                context,
                delegate: _DemoSearchDelegate(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Charts Tab ────────────────────────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  const _ChartsTab();

  static final _lineSeries = [
    const AppChartSeries(
      name: 'Revenue',
      points: [
        AppChartPoint(0, 10), AppChartPoint(1, 28),
        AppChartPoint(2, 22), AppChartPoint(3, 45),
        AppChartPoint(4, 38), AppChartPoint(5, 62),
        AppChartPoint(6, 58), AppChartPoint(7, 80),
      ],
    ),
    const AppChartSeries(
      name: 'Orders',
      filled: false,
      points: [
        AppChartPoint(0, 5), AppChartPoint(1, 15),
        AppChartPoint(2, 18), AppChartPoint(3, 30),
        AppChartPoint(4, 25), AppChartPoint(5, 48),
        AppChartPoint(6, 40), AppChartPoint(7, 60),
      ],
    ),
  ];

  static const _barData = [
    AppBarData(label: 'Mon', value: 42),
    AppBarData(label: 'Tue', value: 78),
    AppBarData(label: 'Wed', value: 55),
    AppBarData(label: 'Thu', value: 90),
    AppBarData(label: 'Fri', value: 67),
    AppBarData(label: 'Sat', value: 110),
    AppBarData(label: 'Sun', value: 85),
  ];

  static const _pieSections = [
    AppPieSection(label: 'Food', value: 35),
    AppPieSection(label: 'Electronics', value: 28),
    AppPieSection(label: 'Fashion', value: 20),
    AppPieSection(label: 'Other', value: 17),
  ];

  static const _sparkData = [2.0, 5.0, 3.0, 8.0, 6.0, 9.0, 7.0, 12.0, 10.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _DemoSection(
          title: 'AppLineChart',
          subtitle: 'Smooth area chart with gradient fill',
          icon: Icons.show_chart_rounded,
          color: const Color(0xFF7C3AED),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppLineChart(
                series: _lineSeries,
                height: 200,
                showDots: false,
                xLabelBuilder: (x) {
                  final idx = x.toInt();
                  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  if (idx >= 0 && idx < labels.length) return labels[idx];
                  return labels[idx % labels.length];
                },
              ),
            ),
          ],
        ),
        const _DemoSection(
          title: 'AppBarChart',
          subtitle: 'Vertical bar chart with touch tooltips',
          icon: Icons.bar_chart_rounded,
          color: Color(0xFF0891B2),
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppBarChart(
                data: _barData,
                height: 180,
              ),
            ),
          ],
        ),
        const _DemoSection(
          title: 'AppPieChart',
          subtitle: 'Donut chart with legend',
          icon: Icons.pie_chart_rounded,
          color: Color(0xFF16A34A),
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppPieChart(
                sections: _pieSections,
                height: 200,
                donut: true,
                centerText: 'Sales\nMix',
              ),
            ),
          ],
        ),
        const _DemoSection(
          title: 'AppSparkline',
          subtitle: 'Inline compact trend chart',
          icon: Icons.trending_up_rounded,
          color: Color(0xFFD97706),
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.md,
                children: [
                  _SparkCard(
                    label: 'Revenue', value: '₹2.4L',
                    data: _sparkData, color: Color(0xFF16A34A)),
                  _SparkCard(
                    label: 'Orders', value: '348',
                    data: [5, 3, 8, 6, 9, 7, 12, 10, 14],
                    color: Color(0xFF7C3AED)),
                  _SparkCard(
                    label: 'Returns', value: '12',
                    data: [8, 6, 4, 5, 3, 2, 4, 3, 2],
                    color: Color(0xFFDC2626)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SparkCard extends StatelessWidget {
  final String label;
  final String value;
  final List<double> data;
  final Color color;

  const _SparkCard({
    required this.label,
    required this.value,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
              Text(value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          AppSparkline(data: data, color: color, height: 36, width: 72),
        ],
      ),
    );
  }
}

// ── Update Checker Tab ────────────────────────────────────────────────────────

class _UpdateCheckerTab extends StatelessWidget {
  const _UpdateCheckerTab();

  @override
  Widget build(BuildContext context) {
    const demoInfo = AppUpdateInfo(
      minVersion: '1.0.0',
      latestVersion: '2.3.1',
      storeUrl: 'https://play.google.com/store',
      releaseNotes:
          '• New checkout flow\n• Performance improvements\n• Bug fixes',
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        _DemoSection(
          title: 'AppUpdateService',
          subtitle: 'Version gate with force-update + optional sheet',
          icon: Icons.system_update_rounded,
          color: const Color(0xFF0891B2),
          children: [
            _DemoButton(
              label: 'Show Optional Update Sheet',
              icon: Icons.new_releases_rounded,
              color: const Color(0xFF0891B2),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl)),
                ),
                builder: (_) => const _AppOptionalUpdateSheetPreview(info: demoInfo),
              ),
            ),
            _DemoButton(
              label: 'Show Force Update Dialog',
              icon: Icons.block_rounded,
              color: const Color(0xFFDC2626),
              onTap: () => showDialog<void>(
                context: context,
                barrierDismissible: true,
                builder: (_) =>
                    const _AppForceUpdateDialogPreview(info: demoInfo),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Preview wrappers to avoid triggering real update logic in showcase
class _AppOptionalUpdateSheetPreview extends StatelessWidget {
  final AppUpdateInfo info;
  const _AppOptionalUpdateSheetPreview({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.new_releases_rounded, color: cs.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Available',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800)),
                  Text('v1.0.0 → v${info.latestVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text("What's New",
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(info.releaseNotes ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: const Text('Later'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Update'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppForceUpdateDialogPreview extends StatelessWidget {
  final AppUpdateInfo info;
  const _AppForceUpdateDialogPreview({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      contentPadding: const EdgeInsets.all(AppSpacing.xl),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.system_update_rounded, size: 36, color: cs.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Update Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please update to v${info.latestVersion} to continue.',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Update Now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
