// ─── AppAnalyticsService ──────────────────────────────────────────────────────
// Firebase Analytics abstraction with screen tracking, events, user properties.
// All calls are no-ops in debug mode — no pollution in development.
//
// Usage:
//   AppAnalyticsService.init();
//   AppAnalyticsService.setCurrentScreen('home_screen');
//   AppAnalyticsService.logEvent('button_tap', {'id': 'cta_hero'});
//   AppAnalyticsService.setUserId('user_123');
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight event model.
class AppAnalyticsEvent {
  final String name;
  final Map<String, Object>? parameters;
  const AppAnalyticsEvent(this.name, {this.parameters});
}

/// Abstract analytics backend — swap Firebase for Amplitude/Mixpanel/etc.
abstract class AppAnalyticsBackend {
  Future<void> logEvent(String name, Map<String, Object>? params);
  Future<void> setCurrentScreen(String screenName);
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String value);
  Future<void> onAppLaunch();
}

/// Null backend — used in debug or when no backend is configured.
class _NoopAnalyticsBackend implements AppAnalyticsBackend {
  @override
  Future<void> logEvent(String name, Map<String, Object>? params) async {}
  @override
  Future<void> setCurrentScreen(String screenName) async {
    debugPrint('[Analytics] screen: $screenName');
  }
  @override
  Future<void> setUserId(String? userId) async {}
  @override
  Future<void> setUserProperty(String name, String value) async {}
  @override
  Future<void> onAppLaunch() async {}
}

class AppAnalyticsService {
  AppAnalyticsService._();

  static AppAnalyticsBackend _backend = _NoopAnalyticsBackend();
  static bool _initialized = false;

  // ── Setup ─────────────────────────────────────────────────────────────────

  /// Call once in bootstrap. Provide a real backend in production.
  /// In debug builds, a no-op backend is always used regardless.
  static void init({AppAnalyticsBackend? backend}) {
    _backend = kDebugMode ? _NoopAnalyticsBackend() : (backend ?? _NoopAnalyticsBackend());
    _initialized = true;
    _backend.onAppLaunch();
  }

  static void _ensureInit() {
    if (!_initialized) init();
  }

  // ── Screen tracking ───────────────────────────────────────────────────────

  /// Call when navigating to a screen.
  /// [screenName] — e.g. 'home', 'product_detail', 'checkout'
  static Future<void> setCurrentScreen(
    String screenName, {
    Map<String, Object>? parameters,
  }) async {
    _ensureInit();
    debugPrint('[Analytics] 📱 screen → $screenName');
    await _backend.setCurrentScreen(screenName);
    if (parameters != null) {
      await _backend.logEvent('screen_view', {
        'screen_name': screenName,
        ...parameters,
      });
    }
  }

  // ── Event logging ─────────────────────────────────────────────────────────

  /// Log a named event with optional parameters.
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    _ensureInit();
    debugPrint('[Analytics] 📌 event → $name  ${parameters ?? ''}');
    await _backend.logEvent(name, parameters);
  }

  /// Log multiple events in sequence.
  static Future<void> logEvents(List<AppAnalyticsEvent> events) async {
    for (final e in events) {
      await logEvent(e.name, parameters: e.parameters);
    }
  }

  // ── Predefined events (type-safe shortcuts) ───────────────────────────────

  static Future<void> logButtonTap(String buttonId, {String? screen}) =>
      logEvent('button_tap',
          parameters: {'button_id': buttonId, if (screen != null) 'screen': screen});

  static Future<void> logSearch(String query) =>
      logEvent('search', parameters: {'query': query});

  static Future<void> logShare(String contentType, {String? contentId}) =>
      logEvent('share', parameters: {
        'content_type': contentType,
        if (contentId != null) 'content_id': contentId,
      });

  static Future<void> logError(String errorName, {String? description}) =>
      logEvent('app_error', parameters: {
        'error_name': errorName,
        if (description != null) 'description': description,
      });

  static Future<void> logFeatureUsed(String featureName) =>
      logEvent('feature_used', parameters: {'feature': featureName});

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<void> setUserId(String? userId) async {
    _ensureInit();
    await _backend.setUserId(userId);
  }

  static Future<void> setUserProperty(String name, String value) async {
    _ensureInit();
    await _backend.setUserProperty(name, value);
  }

  // ── Route observer helper ─────────────────────────────────────────────────

  /// Use with GoRouter's `observers` or Navigator observers.
  /// Example: AppRouter(observers: [AppAnalyticsService.routeObserver])
  static final AppAnalyticsRouteObserver routeObserver =
      AppAnalyticsRouteObserver._();
}

/// NavigatorObserver that auto-tracks screen names from route settings.
class AppAnalyticsRouteObserver extends NavigatorObserver {
  AppAnalyticsRouteObserver._();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      AppAnalyticsService.setCurrentScreen(name);
    }
  }
}
