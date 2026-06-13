// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_kit/core/bootstrap/env_config.dart';
import 'package:enterprise_kit/core/connectivity/connectivity_service.dart';
import 'package:enterprise_kit/core/debug/debug_overlay.dart';
import 'package:enterprise_kit/core/router/app_router.dart';
import 'package:enterprise_kit/core/theme/theme_config.dart';
import 'package:enterprise_kit/core/toast/app_toast.dart';
import 'package:enterprise_kit/shared/widgets/banners/app_banner.dart';
import 'package:enterprise_kit/l10n/l10n.dart';

class EnterpriseApp extends ConsumerStatefulWidget {
  const EnterpriseApp({super.key});

  @override
  ConsumerState<EnterpriseApp> createState() => _EnterpriseAppState();
}

class _EnterpriseAppState extends ConsumerState<EnterpriseApp> {
  /// True only after we have confirmed going offline mid-session.
  /// Prevents the "Back online" toast from firing on cold start when the
  /// connectivity provider briefly emits a disconnected state before
  /// completing its initial internet reachability check.
  bool _wentOfflineDuringSession = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(themeConfigProvider);
    final lightTheme = ref.watch(appLightThemeProvider);
    final darkTheme = ref.watch(appDarkThemeProvider);

    ref.listen(connectivityProvider, (prev, next) {
      final wasConnected = prev?.value?.isConnected;
      final isConnected = next.value?.isConnected;

      if (wasConnected == true && isConnected == false) {
        // Went offline during an active session — show the banner
        _wentOfflineDuringSession = true;
        AppBannerController.instance.dismissByType(AppBannerType.offline);
        AppBannerController.instance.offline();
      } else if (_wentOfflineDuringSession && isConnected == true) {
        // Came back online after a real mid-session disconnect
        _wentOfflineDuringSession = false;
        AppBannerController.instance.dismissByType(AppBannerType.offline);
        AppToastController.instance.success(
          'Back online',
          title: 'Connection restored',
          position: AppToastPosition.top,
        );
      }
    });

    Widget app = MaterialApp.router(
      title: 'Enterprise Kit',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: config.mode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: EnvConfig.enableDebugBanner,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // ── All overlays live INSIDE MaterialApp so MediaQuery is available ──────
      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();

        // 1. Banner overlay (top/bottom persistent banners)
        content = _AppBannerLayer(child: content);

        // 2. Toast overlay (floating notifications)
        content = AppToastOverlay(child: content);

        // 3. Text scale enforcement (optional clamp)
        content = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler
                  .scale(1.0)
                  .clamp(0.8, 1.4),
            ),
          ),
          child: content,
        );

        return content;
      },
    );

    if (EnvConfig.showDebugOverlay) {
      app = DebugOverlay(child: app);
    }

    return app;
  }
}

// ─── App Banner Layer ─────────────────────────────────────────────────────────
// Two rendering modes:
//   strip   (floating: false) → in Column, pushes content, respects SafeArea
//   pill    (floating: true)  → in Stack overlay, never pushes content
class _AppBannerLayer extends StatefulWidget {
  final Widget child;
  const _AppBannerLayer({required this.child});

  @override
  State<_AppBannerLayer> createState() => _AppBannerLayerState();
}

class _AppBannerLayerState extends State<_AppBannerLayer> {
  @override
  void initState() {
    super.initState();
    AppBannerController.instance.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppBannerController.instance.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl        = AppBannerController.instance;
    final mq          = MediaQuery.of(context);
    final topStrips   = ctrl.topBanners   .where((b) => !b.floating).toList();
    final topPills    = ctrl.topBanners   .where((b) =>  b.floating).toList();
    final bottomStrips = ctrl.bottomBanners.where((b) => !b.floating).toList();
    final bottomPills  = ctrl.bottomBanners.where((b) =>  b.floating).toList();

    return Stack(
      children: [
        // ── Column layout: strips push content ───────────────────────────
        Column(
          children: [
            // Top strips (status-bar inset handled inside AppBannerWidget)
            ...topStrips.map((b) => AppBannerWidget(
              key: ValueKey(b.id),
              banner: b,
              onDismiss: () => ctrl.dismiss(b.id),
            )),
            // Main content
            Expanded(child: widget.child),
            // Bottom strips
            ...bottomStrips.reversed.map((b) => AppBannerWidget(
              key: ValueKey(b.id),
              banner: b,
              onDismiss: () => ctrl.dismiss(b.id),
            )),
          ],
        ),

        // ── Top pills (floating, below status bar) ────────────────────────
        if (topPills.isNotEmpty)
          Positioned(
            top: mq.padding.top + 8,
            left: 20, right: 20,
            child: Column(
              children: topPills.map((b) => AppBannerWidget(
                key: ValueKey(b.id),
                banner: b,
                onDismiss: () => ctrl.dismiss(b.id),
              )).toList(),
            ),
          ),

        // ── Bottom pills (floating, above safe area / nav bar) ────────────
        if (bottomPills.isNotEmpty)
          Positioned(
            bottom: mq.padding.bottom + 16,
            left: 20, right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: bottomPills.reversed.map((b) => AppBannerWidget(
                key: ValueKey(b.id),
                banner: b,
                onDismiss: () => ctrl.dismiss(b.id),
              )).toList(),
            ),
          ),
      ],
    );
  }
}
