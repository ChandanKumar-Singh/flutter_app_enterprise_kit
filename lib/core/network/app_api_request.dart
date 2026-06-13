// ─── AppApiRequest + AppApiResult + ApiMethod ─────────────────────────────────
// Central types for the AppApiClientService.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';

// ─── ApiMethod ────────────────────────────────────────────────────────────────

enum ApiMethod {
  get,
  post,
  put,
  patch,
  delete,

  /// Multipart file upload (FormData). Requires [AppApiRequest.formData].
  multipart;

  String get httpMethod => switch (this) {
        ApiMethod.get       => 'GET',
        ApiMethod.post      => 'POST',
        ApiMethod.put       => 'PUT',
        ApiMethod.patch     => 'PATCH',
        ApiMethod.delete    => 'DELETE',
        ApiMethod.multipart => 'POST',
      };
}

// ─── AppApiError ──────────────────────────────────────────────────────────────

enum AppApiError {
  /// Device has no internet connection.
  noConnectivity,

  /// Request / receive / send timed out.
  timeout,

  /// 401 — token missing or expired and refresh failed.
  unauthorized,

  /// 403 — token valid but insufficient permissions.
  forbidden,

  /// 404 — resource not found.
  notFound,

  /// 422 — validation / business-logic error from server.
  unprocessable,

  /// 5xx — server-side error.
  serverError,

  /// Request was cancelled (e.g. widget disposed).
  cancelled,

  /// Response could not be decoded / fromJson threw.
  parse,

  /// Any other error.
  unknown;

  /// User-facing short label.
  String get label => switch (this) {
        AppApiError.noConnectivity => 'No connection',
        AppApiError.timeout        => 'Request timed out',
        AppApiError.unauthorized   => 'Unauthorized',
        AppApiError.forbidden      => 'Access denied',
        AppApiError.notFound       => 'Not found',
        AppApiError.unprocessable  => 'Validation error',
        AppApiError.serverError    => 'Server error',
        AppApiError.cancelled      => 'Cancelled',
        AppApiError.parse          => 'Parse error',
        AppApiError.unknown        => 'Unknown error',
      };

  bool get isRetryable =>
      this == AppApiError.timeout || this == AppApiError.serverError;
}

// ─── AppApiRequest ────────────────────────────────────────────────────────────

class AppApiRequest<T> {
  // ── Path + method ──────────────────────────────────────────────────────────

  /// Relative path (e.g. 'posts/1') or absolute URL.
  final String path;

  /// HTTP method. Defaults to [ApiMethod.post].
  final ApiMethod method;

  // ── Payload ────────────────────────────────────────────────────────────────

  /// URL query parameters.
  final Map<String, dynamic>? queryParams;

  /// Request body (Map / List / String). Ignored for multipart.
  final dynamic body;

  /// FormData for [ApiMethod.multipart] uploads.
  final FormData? formData;

  /// Extra headers merged into this request only.
  final Map<String, String>? extraHeaders;

  // ── Auth ───────────────────────────────────────────────────────────────────

  /// Whether to attach the bearer token. Default: true.
  final bool isAuth;

  // ── Cache ──────────────────────────────────────────────────────────────────

  /// Whether to read from / write to the response cache. Default: false.
  final bool canCache;

  /// Custom cache key. Falls back to `<METHOD>:<URI>` when null.
  final String? cacheKey;

  /// How long to keep the cached response. Default: 5 minutes.
  final Duration cacheDuration;

  /// Force-bypass cache read (re-fetch even if a valid entry exists).
  final bool forceRefresh;

  // ── Retry ──────────────────────────────────────────────────────────────────

  /// Whether to retry on transient failures. Default: true.
  final bool canRetry;

  /// Override the global retry count for this request.
  final int? retryCount;

  /// Override per-attempt retry delay (ms).
  final int? retryDelayMs;

  // ── Timeout ────────────────────────────────────────────────────────────────

  /// Override global connect timeout for this request.
  final Duration? connectTimeoutOverride;

  /// Override global receive timeout for this request.
  final Duration? receiveTimeoutOverride;

  // ── Response parsing ───────────────────────────────────────────────────────

  /// Transform `response.data` into T.
  /// If null, [AppApiClientService] casts `response.data` directly to T.
  final T Function(dynamic json)? fromJson;

  // ── Progress ───────────────────────────────────────────────────────────────

  final ProgressCallback? onSendProgress;
  final ProgressCallback? onReceiveProgress;

  // ── Metadata ──────────────────────────────────────────────────────────────

  /// Optional tag for logging / analytics (e.g. 'fetchUserProfile').
  final String? tag;

  const AppApiRequest({
    required this.path,
    this.method         = ApiMethod.post,
    this.queryParams,
    this.body,
    this.formData,
    this.extraHeaders,
    this.isAuth         = true,
    this.canCache       = false,
    this.cacheKey,
    this.cacheDuration  = const Duration(minutes: 5),
    this.forceRefresh   = false,
    this.canRetry       = true,
    this.retryCount,
    this.retryDelayMs,
    this.connectTimeoutOverride,
    this.receiveTimeoutOverride,
    this.fromJson,
    this.onSendProgress,
    this.onReceiveProgress,
    this.tag,
  });

  AppApiRequest<T> copyWith({
    String? path,
    ApiMethod? method,
    Map<String, dynamic>? queryParams,
    dynamic body,
    FormData? formData,
    Map<String, String>? extraHeaders,
    bool? isAuth,
    bool? canCache,
    String? cacheKey,
    Duration? cacheDuration,
    bool? forceRefresh,
    bool? canRetry,
    int? retryCount,
    int? retryDelayMs,
    Duration? connectTimeoutOverride,
    Duration? receiveTimeoutOverride,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    String? tag,
  }) =>
      AppApiRequest<T>(
        path:                   path                   ?? this.path,
        method:                 method                 ?? this.method,
        queryParams:            queryParams            ?? this.queryParams,
        body:                   body                   ?? this.body,
        formData:               formData               ?? this.formData,
        extraHeaders:           extraHeaders           ?? this.extraHeaders,
        isAuth:                 isAuth                 ?? this.isAuth,
        canCache:               canCache               ?? this.canCache,
        cacheKey:               cacheKey               ?? this.cacheKey,
        cacheDuration:          cacheDuration          ?? this.cacheDuration,
        forceRefresh:           forceRefresh           ?? this.forceRefresh,
        canRetry:               canRetry               ?? this.canRetry,
        retryCount:             retryCount             ?? this.retryCount,
        retryDelayMs:           retryDelayMs           ?? this.retryDelayMs,
        connectTimeoutOverride: connectTimeoutOverride ?? this.connectTimeoutOverride,
        receiveTimeoutOverride: receiveTimeoutOverride ?? this.receiveTimeoutOverride,
        fromJson:               fromJson               ?? this.fromJson,
        onSendProgress:         onSendProgress         ?? this.onSendProgress,
        onReceiveProgress:      onReceiveProgress      ?? this.onReceiveProgress,
        tag:                    tag                    ?? this.tag,
      );
}

// ─── AppApiResult ─────────────────────────────────────────────────────────────

sealed class AppApiResult<T> {
  const AppApiResult();

  bool get isSuccess => this is AppApiSuccess<T>;
  bool get isFailure => this is AppApiFailure<T>;

  T? get dataOrNull =>
      this is AppApiSuccess<T> ? (this as AppApiSuccess<T>).data : null;

  String? get errorMessageOrNull =>
      this is AppApiFailure<T> ? (this as AppApiFailure<T>).message : null;

  /// Map over both cases — similar to Either.fold.
  R when<R>({
    required R Function(AppApiSuccess<T> success) success,
    required R Function(AppApiFailure<T> failure) failure,
  }) =>
      switch (this) {
        final AppApiSuccess<T> s => success(s),
        final AppApiFailure<T> f => failure(f),
      };
}

class AppApiSuccess<T> extends AppApiResult<T> {
  final T data;
  final int? statusCode;

  /// True when response came from the local cache (no network request was made).
  final bool fromCache;

  /// Wall-clock milliseconds the request took (0 when fromCache).
  final int elapsedMs;

  const AppApiSuccess({
    required this.data,
    this.statusCode,
    this.fromCache = false,
    this.elapsedMs = 0,
  });
}

class AppApiFailure<T> extends AppApiResult<T> {
  final String message;
  final AppApiError error;
  final int? statusCode;

  /// Raw server response body (Map / String / null).
  final dynamic rawData;

  /// Original exception for logging / Crashlytics.
  final Object? exception;

  const AppApiFailure({
    required this.message,
    required this.error,
    this.statusCode,
    this.rawData,
    this.exception,
  });
}
