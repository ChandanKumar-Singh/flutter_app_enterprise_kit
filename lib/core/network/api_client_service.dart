// ─── AppApiClientService ──────────────────────────────────────────────────────
// Implements IApiClientService on top of ApiClient (Dio).
//
// ══ Multiple instances ══════════════════════════════════════════════════════
//
//   // 1. Default singleton (production config from EnvConfig)
//   AppApiClientService.instance.get('posts');
//
//   // 2. Named instance — different base URL / config
//   final showcase = AppApiClientService(
//     config: AppApiClientConfig.jsonPlaceholder(),
//   );
//
//   // 3. Backend with { "data": <payload> } envelope — auto-unwrapped
//   final myApi = AppApiClientService(
//     config: AppApiClientConfig.withDataEnvelope(baseUrl: 'https://api.myapp.com'),
//   );
//
//   // 4. Register + retrieve by name
//   AppApiServiceRegistry.register('myApi', myApi);
//   AppApiServiceRegistry.get('myApi').get<List<Product>>('products', ...);
//
//   // 5. Extend for per-backend overrides
//   class MyBackendService extends AppApiClientService {
//     MyBackendService() : super(config: AppApiClientConfig.withDataEnvelope(
//       baseUrl: 'https://my-backend.com',
//     ));
//
//     Future<AppApiResult<User>> getUser(String id) =>
//       get('users/$id', fromJson: User.fromJson);
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/debug/app_logger.dart';
import 'package:enterprise_kit/core/errors/network_exception.dart';
import 'package:enterprise_kit/core/network/api_client.dart';
import 'package:enterprise_kit/core/network/app_api_client_config.dart';
import 'package:enterprise_kit/core/network/app_api_request.dart';
import 'package:enterprise_kit/core/network/i_api_client_service.dart';

class AppApiClientService implements IApiClientService {
  // ─── Default singleton (backward-compat) ─────────────────────────────────

  static AppApiClientService? _defaultInstance;

  /// Default production instance — base URL comes from EnvConfig.
  static AppApiClientService get instance =>
      _defaultInstance ??= AppApiClientService();

  /// Override the default singleton (e.g. in tests or bootstrap).
  static void setDefaultInstance(AppApiClientService service) =>
      _defaultInstance = service;

  // ─── Constructor ─────────────────────────────────────────────────────────

  /// Create a service instance with a specific config.
  /// Multiple instances are fully independent — separate Dio, separate cache.
  AppApiClientService({AppApiClientConfig? config})
      : _client = ApiClient(config: config);

  // ─── Internal state ───────────────────────────────────────────────────────

  final ApiClient _client;

  /// The config driving this instance.
  AppApiClientConfig get config => _client.config;

  /// Direct access to the underlying Dio client for advanced use-cases.
  ApiClient get rawClient => _client;

  // ─── Config delegation ─────────────────────────────────────────────────────

  @override
  void updateBaseUrl(String url) => _client.updateBaseUrl(url);

  @override
  void updateHeaders(Map<String, String> headers) => _client.updateHeaders(headers);

  @override
  void removeHeader(String key) => _client.removeHeader(key);

  @override
  void updateTimeout({Duration? connect, Duration? receive, Duration? send}) =>
      _client.updateTimeout(connect: connect, receive: receive, send: send);

  @override
  void setAuthToken(String token) => _client.setAuthToken(token);

  @override
  void clearAuthToken() => _client.clearAuthToken();

  @override
  void clearCache() => _client.clearCache();

  @override
  void clearCacheKey(String key) => _client.clearCacheKey(key);

  String get baseUrl => _client.dio.options.baseUrl;

  // ─── Core request ─────────────────────────────────────────────────────────

  @override
  Future<AppApiResult<T>> request<T>(AppApiRequest<T> req) async {
    final stopwatch = Stopwatch()..start();
    final tag = req.tag ?? req.path;

    try {
      final options  = _buildOptions(req);
      final response = await _dispatch<T>(req, options);
      stopwatch.stop();

      final fromCache = response.extra['fromCache'] == true;

      AppLogger.instance.d(
        '[${config.label}] ✓ ${req.method.httpMethod} $tag'
        ' — ${fromCache ? "CACHE" : "${stopwatch.elapsedMilliseconds}ms"}'
        ' — ${response.statusCode}',
      );

      // Apply response transformer (unwrap envelope) then parse
      final transformed = config.responseTransformer(
        response.data,
        response.statusCode,
        _flattenHeaders(response.headers),
      );

      final data = _parse<T>(transformed, req.fromJson);

      return AppApiSuccess<T>(
        data:       data,
        statusCode: response.statusCode,
        fromCache:  fromCache,
        elapsedMs:  fromCache ? 0 : stopwatch.elapsedMilliseconds,
      );
    } on DioException catch (e, stack) {
      stopwatch.stop();
      return _handleDioError<T>(e, stack, tag, req.method);
    } on AppApiParseException catch (e) {
      AppLogger.instance.e('[${config.label}] parse error [$tag]: ${e.message}');
      return AppApiFailure<T>(
        message:   'Failed to parse response: ${e.message}',
        error:     AppApiError.parse,
        exception: e,
      );
    } on SocketException catch (e) {
      AppLogger.instance.w('[${config.label}] socket error [$tag]: $e');
      return AppApiFailure<T>(
        message:   'No internet connection',
        error:     AppApiError.noConnectivity,
        exception: e,
      );
    } catch (e, stack) {
      AppLogger.instance.e('[${config.label}] unknown error [$tag]: $e\n$stack');
      return AppApiFailure<T>(
        message:   e.toString(),
        error:     AppApiError.unknown,
        exception: e,
      );
    }
  }

  // ─── Convenience wrappers ─────────────────────────────────────────────────

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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
        path:            path,
        method:          ApiMethod.multipart,
        formData:        formData,
        isAuth:          isAuth,
        canRetry:        canRetry,
        onSendProgress:  onSendProgress,
        fromJson:        fromJson,
        tag:             tag,
      ));

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Options _buildOptions<T>(AppApiRequest<T> req) {
    final extra = <String, dynamic>{
      if (!req.isAuth)              'skipAuth':     true,
      if (!req.canRetry)            'noRetry':      true,
      if (req.retryCount != null)   'maxRetries':   req.retryCount,
      if (req.retryDelayMs != null) 'retryDelayMs': req.retryDelayMs,
      if (req.canCache)             'cacheTtl':     req.cacheDuration,
      if (req.cacheKey != null)     'cacheKey':     req.cacheKey,
      if (req.forceRefresh)         'noCache':      true,
    };

    final headers = <String, dynamic>{};
    if (req.extraHeaders != null) headers.addAll(req.extraHeaders!);

    return Options(
      method:         req.method.httpMethod,
      headers:        headers.isNotEmpty ? headers : null,
      extra:          extra,
      sendTimeout:    req.connectTimeoutOverride,
      receiveTimeout: req.receiveTimeoutOverride,
    );
  }

  Future<Response<T>> _dispatch<T>(AppApiRequest<T> req, Options opts) =>
      switch (req.method) {
        ApiMethod.get       => _client.get<T>(req.path, params: req.queryParams, options: opts),
        ApiMethod.post      => _client.post<T>(req.path, data: req.body, options: opts),
        ApiMethod.put       => _client.put<T>(req.path, data: req.body, options: opts),
        ApiMethod.patch     => _client.patch<T>(req.path, data: req.body, options: opts),
        ApiMethod.delete    => _client.delete<T>(req.path, options: opts),
        ApiMethod.multipart => _client.upload<T>(
            req.path,
            formData:       req.formData!,
            onSendProgress: req.onSendProgress,
            options:        opts,
          ),
      };

  T _parse<T>(dynamic raw, T Function(dynamic)? fromJson) {
    if (fromJson != null) {
      try {
        return fromJson(raw);
      } catch (e) {
        throw AppApiParseException(e.toString());
      }
    }
    try {
      return raw as T;
    } catch (e) {
      throw AppApiParseException(
        'Cannot cast ${raw.runtimeType} to $T. Provide a fromJson callback.',
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
      '[${config.label}] ✗ ${method.httpMethod} $tag — ${ne.statusCode} ${ne.message}',
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

  Map<String, dynamic> _flattenHeaders(Headers headers) {
    final result = <String, dynamic>{};
    headers.forEach((k, v) => result[k.toLowerCase()] = v.join(', '));
    return result;
  }
}

// ─── Internal exception ───────────────────────────────────────────────────────

class AppApiParseException implements Exception {
  final String message;
  const AppApiParseException(this.message);
  @override
  String toString() => 'AppApiParseException: $message';
}
