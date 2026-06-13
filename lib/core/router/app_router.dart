// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/router/route_names.dart';
import 'package:enterprise_kit/features/splash/splash_page.dart';
import 'package:enterprise_kit/features/home/home_page.dart';
import 'package:enterprise_kit/features/showcase/showcase_home_page.dart';
import 'package:enterprise_kit/features/showcase/buttons_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/cards_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/dialogs_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/sheets_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/inputs_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/theme_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/images_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/typography_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/charts_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/network_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/utils_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/animations_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/loaders_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/pdf_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/states_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/components_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/theme_config_page.dart';
import 'package:enterprise_kit/features/showcase/ui_kit_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/food_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/advanced_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/services_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/navigation_showcase_page.dart';
import 'package:enterprise_kit/features/showcase/notification_center_showcase_page.dart';

/// Shared fade+slide transition used across all routes.
CustomTransitionPage<T> _fadeSlide<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (ctx, animation, secondary, c) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: c),
      );
    },
  );
}

/// Shared bottom-up slide transition for sub-pages.
CustomTransitionPage<T> _slideUp<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (ctx, animation, secondary, c) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutQuint);
      final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curve);
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: c));
    },
  );
}


class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (c, s) => _fadeSlide(c, s, const SplashPage()),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        pageBuilder: (c, s) => _fadeSlide(c, s, const HomePage()),
      ),
      GoRoute(
        path: RouteNames.showcase,
        name: 'showcase',
        pageBuilder: (c, s) => _fadeSlide(c, s, const ShowcaseHomePage()),
        routes: [
          GoRoute(path: 'buttons',    pageBuilder: (c, s) => _slideUp(c, s, const ButtonsShowcasePage())),
          GoRoute(path: 'cards',      pageBuilder: (c, s) => _slideUp(c, s, const CardsShowcasePage())),
          GoRoute(path: 'dialogs',    pageBuilder: (c, s) => _slideUp(c, s, const DialogsShowcasePage())),
          GoRoute(path: 'sheets',     pageBuilder: (c, s) => _slideUp(c, s, const SheetsShowcasePage())),
          GoRoute(path: 'inputs',     pageBuilder: (c, s) => _slideUp(c, s, const InputsShowcasePage())),
          GoRoute(path: 'theme',      pageBuilder: (c, s) => _slideUp(c, s, const ThemeShowcasePage())),
          GoRoute(path: 'images',     pageBuilder: (c, s) => _slideUp(c, s, const ImagesShowcasePage())),
          GoRoute(path: 'typography', pageBuilder: (c, s) => _slideUp(c, s, const TypographyShowcasePage())),
          GoRoute(path: 'charts',     pageBuilder: (c, s) => _slideUp(c, s, const ChartsShowcasePage())),
          GoRoute(path: 'network',    pageBuilder: (c, s) => _slideUp(c, s, const NetworkShowcasePage())),
          GoRoute(path: 'utils',      pageBuilder: (c, s) => _slideUp(c, s, const UtilsShowcasePage())),
          GoRoute(path: 'animations', pageBuilder: (c, s) => _slideUp(c, s, const AnimationsShowcasePage())),
          GoRoute(path: 'loaders',    pageBuilder: (c, s) => _slideUp(c, s, const LoadersShowcasePage())),
          GoRoute(path: 'pdf',        pageBuilder: (c, s) => _slideUp(c, s, const PdfShowcasePage())),
          GoRoute(path: 'states',     pageBuilder: (c, s) => _slideUp(c, s, const StatesShowcasePage())),
          GoRoute(path: 'components', pageBuilder: (c, s) => _slideUp(c, s, const ComponentsShowcasePage())),
          GoRoute(path: 'theme-config', pageBuilder: (c, s) => _slideUp(c, s, const ThemeConfigPage())),
          GoRoute(path: 'ui-kit',     pageBuilder: (c, s) => _slideUp(c, s, const UiKitShowcasePage())),
          GoRoute(path: 'food',       pageBuilder: (c, s) => _slideUp(c, s, const FoodShowcasePage())),
          GoRoute(path: 'advanced',   pageBuilder: (c, s) => _slideUp(c, s, const AdvancedShowcasePage())),
          // Sprint 2 — services, infrastructure & components
          GoRoute(path: 'services',       pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'notifications',  pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'feature-flags',  pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'biometric',      pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'encrypted-storage', pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'repository',     pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'wizard',         pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'search',         pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'charts-v2',      pageBuilder: (c, s) => _slideUp(c, s, const ServicesShowcasePage())),
          GoRoute(path: 'navigation',             pageBuilder: (c, s) => _slideUp(c, s, const NavigationShowcasePage())),
          GoRoute(path: 'notification-center',  pageBuilder: (c, s) => _slideUp(c, s, const NotificationCenterShowcasePage())),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.danger, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
          ],
        ),
      ),
    ),
  );
}
