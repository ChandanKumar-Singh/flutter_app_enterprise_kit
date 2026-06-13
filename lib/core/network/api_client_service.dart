// ─── AppApiClientService ──────────────────────────────────────────────────────
// High-level HTTP service built on top of ApiClient.
//
// Usage:
//   final result = await AppApiClientService.instance.request(
//     AppApiRequest<List<Post>>(
//       path: 'posts',
//       method: ApiMethod.get,
//       canCache: true,
//       cacheDuration: Duration(minutes: 10),
//       fromJson: (json) => (json as List).map((e) => Post.fromJson(e)).toList(),
//     ),
//   );
//   result.when(
//     success: (s) => setState(() => posts = s.data),
//     failure: (f) => showError(f.message),
//   );
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/debug/app_logger.dart';
import 'package:enterprise_kit/core/errors/network_exception.dart';
import 'package:enterprise_kit/core/network/api_client.dart';
import 'package:enterprise_kit/core/network/app_api_request.dart';

class AppApiClientService {
  // ─── Singleton ──────────────────────────────────────────────────────────────

  AppApiClientService._();
  static AppApiClientService? _instance;
  static AppApiClientService get instance =>
      _instance ??= AppApiClientService._();

  /// Swap out the underlying client (e.g. in tests with a mock).
  static void overrideInstance(AppApiClientService service) =>
      _instance = service;

  // ─── Internal state ─────────────────────────────────────────────────────────

  final ApiClient _client = ApiClient();

  // ─── Config delegation ───────────────────────────────────────────────────────

  /// Direct access to the underlying ApiClient for advanced use-cases.
  ApiClient get client => _client;

  /// Change base URL at runtime.
  void updateBaseUrl(String url) => _client.updateBaseUrl(url);

  /// Merge default headers.
  void updateHeaders(Map<String, String> headers) =>
      _client.updateHeaders(headers);

  /// Remove a default header.
  void removeHeader(String key) => _client.removeHeader(key);

  /// Override timeouts.
  void updateTimeout({Duration? connect, Duration? receive, Duration? send}) =>
      _client.updateTimeout(connect: connect, receive: receive, send: send);

  /// Set bearer token.
  void setAuthToken(String token) => _client.setAuthToken(token);

  /// Clear bearer token.
  void clearAuthToken() => _client.clearAuthToken();

  /// Wipe entire cache.
  void clearCache() => _client.clearCache();

  /// Wipe a specific cache entry.
  void clearCacheKey(String key) => _client.clearCacheKey(key);

  /// Current base URL.
  String get baseUrl => _client.dio.options.baseUrl;

  // ─── Core request method ─────────────────────────────────────────────────────

  /// Execute any HTTP request described by [req] and return a typed result.
  ///
  /// All options have sensible defaults; only [path] is required.
  Future<AppApiResult<T>> request<T>(AppApiRequest<T> req) async {
    final stopwatch = Stopwatch()..start();
    final tag = req.tag ?? req.path;

    try {
      final options = _buildOptions(req);
      final response = await _dispatch<T>(req, options);
      stopwatch.stop();

      // Cache hit — interceptor resolved with fromCache = true
      final fromCache = response.extra['fromCache'] == true;

      AppLogger.instance.d(
        'API ✓ [${req.method.httpMethod}] $tag'
        ' — ${fromCache ? "CACHE" : "${stopwatch.elapsedMilliseconds}ms"}'
        ' — ${response.statusCode}',
      );

      final data = _parse<T>(response.data, req.fromJson);
      return AppApiSuccess<T>(
        data: data,
        statusCode: response.statusCode,
        fromCache: fromCache,
        elapsedMs: fromCache ? 0 : stopwatch.elapsedMilliseconds,
      );
    } on DioException catch (e, stack) {
      stopwatch.stop();
      return _handleDioError<T>(e, stack, tag, req.method);
    } on AppApiParseException catch (e) {
      AppLogger.instance.e('API parse error [$tag]: ${e.message}');
      return AppApiFailure<T>(
        message: 'Failed to parse response: ${e.message}',
        error: AppApiError.parse,
        exception: e,
      );
    } on SocketException catch (e) {
      AppLogger.instance.w('API socket error [$tag]: $e');
      return AppApiFailure<T>(
        message: 'No internet connection',
        error: AppApiError.noConnectivity,
        exception: e,
      );
    } catch (e, stack) {
      AppLogger.instance.e('API unknown error [$tag]: $e\n$stack');
      return AppApiFailure<T>(
        message: e.toString(),
        error: AppApiError.unknown,
        exception: e,
      );
    }
  }

  // ─── Convenience wrappers ────────────────────────────────────────────────────

  /// GET shorthand.
  Future<AppApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    bool isAuth       = true,
    bool canCache     = false,
    String? cacheKey,
    Duration cacheDuration = const Duration(minutes: 5),
    bool canRetry     = true,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:          path,
        method:        ApiMethod.get,
        queryParams:   queryParams,
        isAuth:        isAuth,
        canCache:      canCache,
        cacheKey:      cacheKey,
        cacheDuration: cacheDuration,
        canRetry:      canRetry,
        fromJson:      fromJson,
        tag:           tag,
      ));

  /// POST shorthand.
  Future<AppApiResult<T>> post<T>(
    String path, {
    dynamic body,
    bool isAuth   = true,
    bool canRetry = false,
    Map<String, String>? extraHeaders,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:         path,
        method:       ApiMethod.post,
        body:         body,
        isAuth:       isAuth,
        canRetry:     canRetry,
        extraHeaders: extraHeaders,
        fromJson:     fromJson,
        tag:          tag,
      ));

  /// PUT shorthand.
  Future<AppApiResult<T>> put<T>(
    String path, {
    dynamic body,
    bool isAuth   = true,
    bool canRetry = false,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:     path,
        method:   ApiMethod.put,
        body:     body,
        isAuth:   isAuth,
        canRetry: canRetry,
        fromJson: fromJson,
        tag:      tag,
      ));

  /// PATCH shorthand.
  Future<AppApiResult<T>> patch<T>(
    String path, {
    dynamic body,
    bool isAuth   = true,
    bool canRetry = false,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:     path,
        method:   ApiMethod.patch,
        body:     body,
        isAuth:   isAuth,
        canRetry: canRetry,
        fromJson: fromJson,
        tag:      tag,
      ));

  /// DELETE shorthand.
  Future<AppApiResult<T>> delete<T>(
    String path, {
    bool isAuth   = true,
    bool canRetry = false,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:     path,
        method:   ApiMethod.delete,
        isAuth:   isAuth,
        canRetry: canRetry,
        fromJson: fromJson,
        tag:      tag,
      ));

  /// Multipart / file-upload shorthand.
  Future<AppApiResult<T>> upload<T>(
    String path, {
    required FormData formData,
    bool isAuth              = true,
    bool canRetry            = false,
    ProgressCallback? onSendProgress,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:             path,
        method:           ApiMethod.multipart,
        formData:         formData,
        isAuth:           isAuth,
        canRetry:         canRetry,
        onSendProgress:   onSendProgress,
        fromJson:         fromJson,
        tag:              tag,
      ));

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Options _buildOptions<T>(AppApiRequest<T> req) {
    final extra = <String, dynamic>{
      if (!req.isAuth)                   'skipAuth':    true,
      if (!req.canRetry)                 'noRetry':     true,
      if (req.retryCount != null)        'maxRetries':  req.retryCount,
      if (req.retryDelayMs != null)      'retryDelayMs': req.retryDelayMs,
      if (req.canCache)                  'cacheTtl':    req.cacheDuration,
      if (req.cacheKey != null)          'cacheKey':    req.cacheKey,
      if (req.forceRefresh)              'noCache':     true,
      if (req.method == ApiMethod.multipart) 'forceCache': false,
    };

    final Duration? connectTimeout = req.connectTimeoutOverride;
    final Duration? receiveTimeout = req.receiveTimeoutOverride;

    final headers = <String, dynamic>{};
    if (req.extraHeaders != null) headers.addAll(req.extraHeaders!);

    return Options(
      method:          req.method.httpMethod,
      headers:         headers.isNotEmpty ? headers : null,
      extra:           extra,
      sendTimeout:     connectTimeout,
      receiveTimeout:  receiveTimeout,
    );
  }

  Future<Response<T>> _dispatch<T>(AppApiRequest<T> req, Options opts) {
    return switch (req.method) {
      ApiMethod.get => _client.get<T>(
          req.path,
          params:  req.queryParams,
          options: opts,
        ),
      ApiMethod.post => _client.post<T>(
          req.path,
          data:    req.body,
          options: opts,
        ),
      ApiMethod.put => _client.put<T>(
          req.path,
          data:    req.body,
          options: opts,
        ),
      ApiMethod.patch => _client.patch<T>(
          req.path,
          data:    req.body,
          options: opts,
        ),
      ApiMethod.delete => _client.delete<T>(
          req.path,
          options: opts,
        ),
      ApiMethod.multipart => _client.upload<T>(
          req.path,
          formData:        req.formData!,
          onSendProgress:  req.onSendProgress,
          options:         opts,
        ),
    };
  }

  T _parse<T>(dynamic raw, T Function(dynamic)? fromJson) {
    if (fromJson != null) {
      try {
        return fromJson(raw);
      } catch (e) {
        throw AppApiParseException(e.toString());
      }
    }
    // No parser: attempt direct cast.
    try {
      return raw as T;
    } catch (e) {
      throw AppApiParseException(
        'Cannot cast ${raw.runtimeType} to $T — provide a fromJson callback.',
      );
    }
  }

  AppApiFailure<T> _handleDioError<T>(
    DioException e,
    StackTrace stack,
    String tag,
    ApiMethod method,
  ) {
    final ne     = NetworkException.fromDioException(e);
    final status = e.response?.statusCode;
    final raw    = e.response?.data;

    AppLogger.instance.w(
      'API ✗ [${method.httpMethod}] $tag — ${ne.statusCode} ${ne.message}',
    );

    final error = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout    ||
      DioExceptionType.sendTimeout       => AppApiError.timeout,
      DioExceptionType.connectionError   => AppApiError.noConnectivity,
      DioExceptionType.cancel            => AppApiError.cancelled,
      DioExceptionType.badResponse       => _errorFromStatus(status),
      _                                  => AppApiError.unknown,
    };

    return AppApiFailure<T>(
      message:    ne.message,
      error:      error,
      statusCode: status,
      rawData:    raw,
      exception:  e,
    );
  }

  AppApiError _errorFromStatus(int? code) => switch (code) {
        401 => AppApiError.unauthorized,
        403 => AppApiError.forbidden,
        404 => AppApiError.notFound,
        422 => AppApiError.unprocessable,
        _ when (code ?? 0) >= 500 => AppApiError.serverError,
        _ => AppApiError.unknown,
      };
}

// ─── Internal exception ───────────────────────────────────────────────────────

class AppApiParseException implements Exception {
  final String message;
  const AppApiParseException(this.message);
  @override
  String toString() => 'AppApiParseException: $message';
}
