// ─── AppNotificationPayload ───────────────────────────────────────────────────
// Typed payload carried in every notification.
// Serialised as JSON in the notification's `payload` string field.
//
// Usage:
//   final p = AppNotificationPayload(
//     action: AppNotificationAction.openScreen,
//     route:  '/orders/123',
//     data:   {'orderId': '123'},
//   );
//   // encode → p.toJson()  |  decode → AppNotificationPayload.fromJson(...)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

// ── Notification actions ──────────────────────────────────────────────────────

enum AppNotificationAction {
  /// Navigate to [route] using GoRouter.
  openScreen,

  /// Open a URL in the browser.
  openUrl,

  /// Trigger a deep-link URI.
  deepLink,

  /// No navigation — informational only.
  none,
}

// ── Payload model ─────────────────────────────────────────────────────────────

class AppNotificationPayload {
  final AppNotificationAction action;

  /// GoRouter route path (for [AppNotificationAction.openScreen]).
  final String? route;

  /// URL string (for [AppNotificationAction.openUrl]).
  final String? url;

  /// Deep-link URI (for [AppNotificationAction.deepLink]).
  final String? deepLinkUri;

  /// Arbitrary extra data passed to the handler.
  final Map<String, dynamic> data;

  /// Notification category / topic (e.g. 'order', 'promo', 'alert').
  final String? category;

  const AppNotificationPayload({
    this.action = AppNotificationAction.none,
    this.route,
    this.url,
    this.deepLinkUri,
    this.data = const {},
    this.category,
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'action': action.name,
        if (route != null) 'route': route,
        if (url != null) 'url': url,
        if (deepLinkUri != null) 'deepLinkUri': deepLinkUri,
        if (data.isNotEmpty) 'data': data,
        if (category != null) 'category': category,
      };

  String toJson() => jsonEncode(toMap());

  factory AppNotificationPayload.fromMap(Map<String, dynamic> map) {
    return AppNotificationPayload(
      action: AppNotificationAction.values.firstWhere(
        (a) => a.name == map['action'],
        orElse: () => AppNotificationAction.none,
      ),
      route: map['route'] as String?,
      url: map['url'] as String?,
      deepLinkUri: map['deepLinkUri'] as String?,
      data: (map['data'] as Map<String, dynamic>?) ?? const {},
      category: map['category'] as String?,
    );
  }

  factory AppNotificationPayload.fromJson(String source) =>
      AppNotificationPayload.fromMap(
        jsonDecode(source) as Map<String, dynamic>,
      );

  // ── Convenience constructors ───────────────────────────────────────────────

  factory AppNotificationPayload.route(
    String route, {
    Map<String, dynamic> data = const {},
    String? category,
  }) =>
      AppNotificationPayload(
        action: AppNotificationAction.openScreen,
        route: route,
        data: data,
        category: category,
      );

  factory AppNotificationPayload.url(
    String url, {
    String? category,
  }) =>
      AppNotificationPayload(
        action: AppNotificationAction.openUrl,
        url: url,
        category: category,
      );

  factory AppNotificationPayload.deepLink(
    String uri, {
    String? category,
  }) =>
      AppNotificationPayload(
        action: AppNotificationAction.deepLink,
        deepLinkUri: uri,
        category: category,
      );

  @override
  String toString() => 'AppNotificationPayload(action: $action, route: $route, '
      'url: $url, category: $category, data: $data)';
}
