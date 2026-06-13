// ─── AppApiClientConfig ───────────────────────────────────────────────────────
// Immutable configuration for one AppApiClientService instance.
//
// Different backends often wrap responses differently. Use [responseTransformer]
// to unwrap the envelope before [AppApiRequest.fromJson] runs:
//
//   // Backend wraps: { "data": {...}, "meta": {...} }
//   responseTransformer: (raw, _, __) => (raw as Map)['data'],
//
//   // Backend wraps: { "result": [...], "code": 200 }
//   responseTransformer: (raw, _, __) => (raw as Map)['result'],
//
//   // Raw response — no wrapping
//   responseTransformer: AppApiResponseTransformer.passthrough,
// ─────────────────────────────────────────────────────────────────────────────

import 'package:enterprise_kit/core/bootstrap/env_config.dart';

// ─── Response transformer ─────────────────────────────────────────────────────

/// Called on the raw `response.data` before [AppApiRequest.fromJson].
/// Return the value you want passed into fromJson (unwrap envelope here).
///
/// Parameters:
///   [rawBody]    — raw response.data (Map / List / String / null)
///   [statusCode] — HTTP status code
///   [headers]    — response headers (lower-case keys)
typedef AppApiResponseTransformer = dynamic Function(
  dynamic rawBody,
  int? statusCode,
  Map<String, dynamic> headers,
);

/// Built-in transformer presets.
abstract class AppApiTransformers {
  AppApiTransformers._();

  /// No transformation — pass response.data straight through (default).
  static dynamic passthrough(dynamic raw, int? _, Map<String, dynamic> __) => raw;

  /// Unwrap `{ "data": <payload> }` envelope.
  static dynamic dataKey(dynamic raw, int? _, Map<String, dynamic> __) =>
      raw is Map && raw.containsKey('data') ? raw['data'] : raw;

  /// Unwrap `{ "result": <payload> }` envelope.
  static dynamic resultKey(dynamic raw, int? _, Map<String, dynamic> __) =>
      raw is Map && raw.containsKey('result') ? raw['result'] : raw;

  /// Unwrap `{ "payload": <payload> }` envelope.
  static dynamic payloadKey(dynamic raw, int? _, Map<String, dynamic> __) =>
      raw is Map && raw.containsKey('payload') ? raw['payload'] : raw;

  /// Unwrap `{ "response": { "body": <payload> } }` deep envelope.
  static dynamic nestedBody(dynamic raw, int? _, Map<String, dynamic> __) {
    if (raw is Map) {
      final inner = raw['response'];
      if (inner is Map) return inner['body'] ?? inner;
    }
    return raw;
  }
}

// ─── Config model ─────────────────────────────────────────────────────────────

class AppApiClientConfig {
  // ── Network ────────────────────────────────────────────────────────────────

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  // ── Default headers ────────────────────────────────────────────────────────

  final Map<String, String> defaultHeaders;

  // ── Feature flags ─────────────────────────────────────────────────────────

  /// Attach bearer token via AuthInterceptor. Default: true.
  final bool enableAuth;

  /// Use in-memory response cache. Default: true.
  final bool enableCache;

  /// Retry on transient failures. Default: true.
  final bool enableRetry;

  /// Log requests + responses. Default: EnvConfig.enableLogging.
  final bool enableLogging;

  /// Track request metrics. Default: true.
  final bool enableMetrics;

  /// Check connectivity before requests. Default: true.
  final bool enableConnectivityCheck;

  // ── Response envelope ──────────────────────────────────────────────────────

  /// Applied to raw response body before [AppApiRequest.fromJson].
  /// Use this to unwrap backend-specific envelopes.
  /// Defaults to [AppApiTransformers.passthrough].
  final AppApiResponseTransformer responseTransformer;

  // ── Retry settings ────────────────────────────────────────────────────────

  final int maxRetries;
  final List<Duration> retryDelays;

  // ── Human-readable label ──────────────────────────────────────────────────

  /// Used in logs and registry listings.
  final String label;

  const AppApiClientConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 60),
    this.sendTimeout    = const Duration(seconds: 30),
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept':       'application/json',
      'X-Client':     'flutter',
      'X-Platform':   'mobile',
    },
    this.enableAuth               = true,
    this.enableCache              = true,
    this.enableRetry              = true,
    this.enableLogging            = false,
    this.enableMetrics            = true,
    this.enableConnectivityCheck  = true,
    this.responseTransformer      = AppApiTransformers.passthrough,
    this.maxRetries               = 3,
    this.retryDelays              = const [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ],
    this.label = 'default',
  });

  // ─── Named constructors ───────────────────────────────────────────────────

  /// Production config — reads base URL from EnvConfig.
  factory AppApiClientConfig.production() => AppApiClientConfig(
        baseUrl:  EnvConfig.baseUrl,
        enableLogging: EnvConfig.enableLogging,
        label:    'production',
      );

  /// JSONPlaceholder demo config for showcase / onboarding demos.
  factory AppApiClientConfig.jsonPlaceholder() => AppApiClientConfig(
        baseUrl:    'https://jsonplaceholder.typicode.com',
        enableAuth: false,
        label:      'jsonplaceholder',
      );

  /// Fast local dev server — verbose logging, shorter timeouts.
  factory AppApiClientConfig.localhost({int port = 8080}) => AppApiClientConfig(
        baseUrl:        'http://localhost:$port',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        enableLogging:  true,
        label:          'localhost:$port',
      );

  /// Backend that wraps responses in `{ "data": <payload> }`.
  factory AppApiClientConfig.withDataEnvelope({
    required String baseUrl,
    String label = 'data-envelope',
  }) =>
      AppApiClientConfig(
        baseUrl:             baseUrl,
        responseTransformer: AppApiTransformers.dataKey,
        label:               label,
      );

  /// Backend that wraps responses in `{ "result": <payload> }`.
  factory AppApiClientConfig.withResultEnvelope({
    required String baseUrl,
    String label = 'result-envelope',
  }) =>
      AppApiClientConfig(
        baseUrl:             baseUrl,
        responseTransformer: AppApiTransformers.resultKey,
        label:               label,
      );

  /// Testing config — no real network calls expected.
  factory AppApiClientConfig.test({String baseUrl = 'http://localhost:9999'}) =>
      AppApiClientConfig(
        baseUrl:                 baseUrl,
        enableLogging:           false,
        enableMetrics:           false,
        enableConnectivityCheck: false,
        connectTimeout:          const Duration(seconds: 3),
        receiveTimeout:          const Duration(seconds: 3),
        label:                   'test',
      );

  AppApiClientConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, String>? defaultHeaders,
    bool? enableAuth,
    bool? enableCache,
    bool? enableRetry,
    bool? enableLogging,
    bool? enableMetrics,
    bool? enableConnectivityCheck,
    AppApiResponseTransformer? responseTransformer,
    int? maxRetries,
    List<Duration>? retryDelays,
    String? label,
  }) =>
      AppApiClientConfig(
        baseUrl:                baseUrl               ?? this.baseUrl,
        connectTimeout:         connectTimeout         ?? this.connectTimeout,
        receiveTimeout:         receiveTimeout         ?? this.receiveTimeout,
        sendTimeout:            sendTimeout            ?? this.sendTimeout,
        defaultHeaders:         defaultHeaders         ?? this.defaultHeaders,
        enableAuth:             enableAuth             ?? this.enableAuth,
        enableCache:            enableCache            ?? this.enableCache,
        enableRetry:            enableRetry            ?? this.enableRetry,
        enableLogging:          enableLogging          ?? this.enableLogging,
        enableMetrics:          enableMetrics          ?? this.enableMetrics,
        enableConnectivityCheck: enableConnectivityCheck ?? this.enableConnectivityCheck,
        responseTransformer:    responseTransformer    ?? this.responseTransformer,
        maxRetries:             maxRetries             ?? this.maxRetries,
        retryDelays:            retryDelays            ?? this.retryDelays,
        label:                  label                  ?? this.label,
      );

  @override
  String toString() => 'AppApiClientConfig($label @ $baseUrl)';
}
