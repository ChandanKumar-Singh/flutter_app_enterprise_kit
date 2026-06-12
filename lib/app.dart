import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_kit/core/bootstrap/env_config.dart';
import 'package:enterprise_kit/core/debug/debug_overlay.dart';
import 'package:enterprise_kit/core/router/app_router.dart';
import 'package:enterprise_kit/core/theme/app_theme.dart';
import 'package:enterprise_kit/core/theme/theme_provider.dart';

class EnterpriseApp extends ConsumerWidget {
  const EnterpriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme  = ref.watch(darkThemeProvider);

    Widget app = MaterialApp.router(
      title: 'Enterprise Kit',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: EnvConfig.enableDebugBanner,
    );

    if (EnvConfig.showDebugOverlay) {
      app = DebugOverlay(child: app);
    }

    return app;
  }
}
