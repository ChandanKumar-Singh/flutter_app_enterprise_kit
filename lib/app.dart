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

class EnterpriseApp extends ConsumerWidget {
  const EnterpriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(themeConfigProvider);
    final lightTheme = ref.watch(appLightThemeProvider);
    final darkTheme = ref.watch(appDarkThemeProvider);

    // Watch connectivity — show/hide offline banner automatically
    ref.listen(connectivityProvider, (prev, next) {
      final wasConnected = prev?.value?.isConnected;
      final isConnected = next.value?.isConnected;
      if (wasConnected == true && isConnected == false) {
        AppBannerController.instance.dismissByType(AppBannerType.offline);
        AppBannerController.instance.offline();
      } else if (wasConnected == false && isConnected == true) {
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
/// Renders app-wide top/bottom banners inside the MaterialApp context.
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

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppBannerController.instance.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AppBannerController.instance;
    return Column(
      children: [
        // Top banners
        ...ctrl.topBanners.map((b) => AppBannerWidget(
              key: ValueKey(b.id),
              message: b.message,
              title: b.title,
              type: b.type,
              actions: b.actions,
              dismissible: b.dismissible,
              onDismiss: () => ctrl.dismiss(b.id),
              leading: b.leading,
            )),
        // Main content
        Expanded(child: widget.child),
        // Bottom banners (reversed so newest is nearest bottom edge)
        ...ctrl.bottomBanners.reversed.map((b) => AppBannerWidget(
              key: ValueKey(b.id),
              message: b.message,
              title: b.title,
              type: b.type,
              actions: b.actions,
              dismissible: b.dismissible,
              onDismiss: () => ctrl.dismiss(b.id),
              leading: b.leading,
            )),
      ],
    );
  }
}
