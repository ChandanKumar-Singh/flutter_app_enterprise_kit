// ─── AppDeepLinkService ───────────────────────────────────────────────────────
// Handles cold-start and in-app deep links via app_links package.
// Routes parsed URIs to GoRouter through an abstract handler interface.
//
// Supports:
//   • Custom URI schemes:     myapp://orders/123
//   • HTTPS universal links:  https://myapp.com/orders/123
//   • Deferred deep links:    Stored and replayed after auth/onboarding
//
// Setup (in AppBootstrap):
//   await AppDeepLinkService.instance.initialize(
//     router: AppRouter.router,
//     handler: _MyDeepLinkHandler(),  // optional custom handler
//   );
//
// Register routes:
//   AppDeepLinkService.instance.registerRoute(
//     pattern: RegExp(r'^/orders/(\w+)$'),
//     builder: (uri, match) => '/orders/${match.group(1)}',
//   );
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

// ── Handler interface ─────────────────────────────────────────────────────────

/// Implement this to intercept deep links before default routing.
/// Return `true` if the link was handled; `false` to fall through to router.
abstract class AppDeepLinkHandler {
  /// Called for every incoming deep link URI.
  /// Return the GoRouter path to navigate to, or `null` to skip routing.
  Future<String?> handle(Uri uri);
}

// ── Route registration ────────────────────────────────────────────────────────

class _RouteRegistration {
  final RegExp pattern;
  final String Function(Uri uri, RegExpMatch match) builder;

  const _RouteRegistration({required this.pattern, required this.builder});
}

// ── Service ───────────────────────────────────────────────────────────────────

class AppDeepLinkService {
  AppDeepLinkService._();
  static final AppDeepLinkService instance = AppDeepLinkService._();

  final _appLinks = AppLinks();
  GoRouter? _router;
  AppDeepLinkHandler? _handler;

  StreamSubscription<Uri>? _sub;
  bool _initialised = false;

  // Deferred deep link — stored when auth is not ready, replayed after login.
  Uri? _deferredLink;

  final _registeredRoutes = <_RouteRegistration>[];

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize({
    required GoRouter router,
    AppDeepLinkHandler? handler,
  }) async {
    if (_initialised) return;
    _router = router;
    _handler = handler;

    // 1. Cold-start link (app was opened via deep link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[AppDeepLinkService] Cold-start link: $initialUri');
        await _processUri(initialUri);
      }
    } catch (e) {
      debugPrint('[AppDeepLinkService] Cold-start error: $e');
    }

    // 2. In-app link stream (app was already running)
    _sub = _appLinks.uriLinkStream.listen(
      (uri) async {
        debugPrint('[AppDeepLinkService] In-app link: $uri');
        await _processUri(uri);
      },
      onError: (Object e) {
        debugPrint('[AppDeepLinkService] Stream error: $e');
      },
    );

    _initialised = true;
    debugPrint('[AppDeepLinkService] Initialised ✓');
  }

  // ── Route registration ──────────────────────────────────────────────────────

  /// Register a URI pattern → GoRouter path mapping.
  ///
  /// Example:
  /// ```dart
  /// AppDeepLinkService.instance.registerRoute(
  ///   pattern: RegExp(r'^/orders/(\w+)$'),
  ///   builder: (uri, match) => '/orders/${match.group(1)}',
  /// );
  /// ```
  void registerRoute({
    required RegExp pattern,
    required String Function(Uri uri, RegExpMatch match) builder,
  }) {
    _registeredRoutes.add(_RouteRegistration(pattern: pattern, builder: builder));
  }

  // ── Deferred deep links ─────────────────────────────────────────────────────

  /// Store a deep link for later — call before auth is ready.
  void deferLink(Uri uri) {
    _deferredLink = uri;
    debugPrint('[AppDeepLinkService] Deferred: $uri');
  }

  /// Replay the deferred link after the user is authenticated.
  /// Returns true if a deferred link was replayed.
  Future<bool> replayDeferred() async {
    final uri = _deferredLink;
    if (uri == null) return false;
    _deferredLink = null;
    await _processUri(uri);
    return true;
  }

  bool get hasDeferredLink => _deferredLink != null;

  // ── Manual navigate ─────────────────────────────────────────────────────────

  /// Programmatically process any URI (e.g. from a push notification payload).
  Future<void> processUri(Uri uri) => _processUri(uri);

  Future<void> processUriString(String uriString) async {
    try {
      await _processUri(Uri.parse(uriString));
    } catch (e) {
      debugPrint('[AppDeepLinkService] Invalid URI: $uriString');
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<void> _processUri(Uri uri) async {
    assert(_router != null, 'Call initialize() before processing links.');

    // 1. Custom handler first
    if (_handler != null) {
      final handlerRoute = await _handler!.handle(uri);
      if (handlerRoute != null) {
        _navigate(handlerRoute);
        return;
      }
    }

    // 2. Registered patterns
    final path = uri.path;
    for (final reg in _registeredRoutes) {
      final match = reg.pattern.firstMatch(path);
      if (match != null) {
        final route = reg.builder(uri, match);
        _navigate(route);
        return;
      }
    }

    // 3. Default: use path directly if it looks like a GoRouter path
    if (path.isNotEmpty && path.startsWith('/')) {
      final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
      _navigate('$path$query');
      return;
    }

    debugPrint('[AppDeepLinkService] No handler for: $uri');
  }

  void _navigate(String route) {
    debugPrint('[AppDeepLinkService] Navigating → $route');
    try {
      _router?.go(route);
    } catch (e) {
      debugPrint('[AppDeepLinkService] Navigation error: $e');
    }
  }

  // ── Dispose ─────────────────────────────────────────────────────────────────

  void dispose() {
    _sub?.cancel();
    _initialised = false;
  }
}

// ── Default handler: maps common URL patterns to app routes ──────────────────

/// A default handler that maps standard HTTPS paths to GoRouter paths.
/// Override with your own [AppDeepLinkHandler] for custom logic.
class AppDefaultDeepLinkHandler implements AppDeepLinkHandler {
  /// Base domains to accept (ignores other origins for security).
  final List<String> allowedHosts;

  /// Path prefix mappings: URL path prefix → app route prefix
  final Map<String, String> pathMappings;

  const AppDefaultDeepLinkHandler({
    this.allowedHosts = const [],
    this.pathMappings = const {},
  });

  @override
  Future<String?> handle(Uri uri) async {
    // Security: reject URIs from unrecognised hosts (HTTPS only)
    if (uri.scheme == 'https' && allowedHosts.isNotEmpty) {
      if (!allowedHosts.contains(uri.host)) {
        debugPrint('[AppDeepLinkHandler] Rejected host: ${uri.host}');
        return null;
      }
    }

    // Apply path mappings
    for (final entry in pathMappings.entries) {
      if (uri.path.startsWith(entry.key)) {
        return uri.path.replaceFirst(entry.key, entry.value);
      }
    }

    return null; // fall through to registered routes
  }
}
