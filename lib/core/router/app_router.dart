import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: RouteNames.showcase,
        name: 'showcase',
        builder: (_, __) => const ShowcaseHomePage(),
        routes: [
          GoRoute(path: 'buttons',    builder: (_, __) => const ButtonsShowcasePage()),
          GoRoute(path: 'cards',      builder: (_, __) => const CardsShowcasePage()),
          GoRoute(path: 'dialogs',    builder: (_, __) => const DialogsShowcasePage()),
          GoRoute(path: 'sheets',     builder: (_, __) => const SheetsShowcasePage()),
          GoRoute(path: 'inputs',     builder: (_, __) => const InputsShowcasePage()),
          GoRoute(path: 'theme',      builder: (_, __) => const ThemeShowcasePage()),
          GoRoute(path: 'images',     builder: (_, __) => const ImagesShowcasePage()),
          GoRoute(path: 'typography', builder: (_, __) => const TypographyShowcasePage()),
          GoRoute(path: 'charts',     builder: (_, __) => const ChartsShowcasePage()),
          GoRoute(path: 'network',    builder: (_, __) => const NetworkShowcasePage()),
          GoRoute(path: 'utils',      builder: (_, __) => const UtilsShowcasePage()),
          GoRoute(path: 'animations', builder: (_, __) => const AnimationsShowcasePage()),
          GoRoute(path: 'loaders',    builder: (_, __) => const LoadersShowcasePage()),
          GoRoute(path: 'pdf',        builder: (_, __) => const PdfShowcasePage()),
          GoRoute(path: 'states',     builder: (_, __) => const StatesShowcasePage()),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
          ],
        ),
      ),
    ),
  );
}
