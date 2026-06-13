import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/network/app_api_client_config.dart';
import 'package:enterprise_kit/core/network/interceptors/auth_interceptor.dart';
import 'package:enterprise_kit/core/network/interceptors/retry_interceptor.dart';
import 'package:enterprise_kit/core/network/interceptors/logging_interceptor.dart';
import 'package:enterprise_kit/core/network/interceptors/connectivity_interceptor.dart';
import 'package:enterprise_kit/core/network/interceptors/cache_interceptor.dart';
import 'package:enterprise_kit/core/network/interceptors/error_interceptor.dart';
import 'package:enterprise_kit/core/network/interceptors/metrics_interceptor.dart';

class ApiClient {
  late final Dio dio;

  /// Exposed for targeted operations (e.g. clearCache, read metrics).
  late final CacheInterceptor cacheInterceptor;
  late final MetricsInterceptor metricsInterceptor;

  final AppApiClientConfig config;

  ApiClient({AppApiClientConfig? config})
      : config = config ?? AppApiClientConfig.production() {
    _init();
  }

  void _init() {
    cacheInterceptor   = CacheInterceptor();
    metricsInterceptor = MetricsInterceptor();

    dio = Dio(
      BaseOptions(
        baseUrl:        _trailingSlash(config.baseUrl),
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout:    config.sendTimeout,
        headers:        Map<String, dynamic>.from(config.defaultHeaders),
      ),
    );

    dio.interceptors.addAll([
      if (config.enableConnectivityCheck) ConnectivityInterceptor(),
      if (config.enableAuth)              AuthInterceptor(),
      if (config.enableCache)             cacheInterceptor,
      if (config.enableRetry)             RetryInterceptor(
        dio:        dio,
        maxRetries: config.maxRetries,
        delays:     config.retryDelays,
      ),
      if (config.enableMetrics)   metricsInterceptor,
      ErrorInterceptor(),
      if (config.enableLogging)   LoggingInterceptor(),
    ]);
  }

  // ─── Runtime config ──────────────────────────────────────────────────────────

  void updateBaseUrl(String url) => dio.options.baseUrl = _trailingSlash(url);
  void updateHeaders(Map<String, String> headers) => dio.options.headers.addAll(headers);
  void removeHeader(String key) => dio.options.headers.remove(key);

  void updateTimeout({Duration? connect, Duration? receive, Duration? send}) {
    if (connect != null) dio.options.connectTimeout = connect;
    if (receive != null) dio.options.receiveTimeout = receive;
    if (send != null)    dio.options.sendTimeout    = send;
  }

  void setAuthToken(String token) =>
      dio.options.headers['Authorization'] = 'Bearer $token';

  void clearAuthToken() => dio.options.headers.remove('Authorization');
  void clearCache() => cacheInterceptor.clearAll();
  void clearCacheKey(String key) => cacheInterceptor.clearKey(key);

  void addInterceptor(Interceptor interceptor) => dio.interceptors.add(interceptor);
  void removeInterceptorOfType<T extends Interceptor>() =>
      dio.interceptors.removeWhere((i) => i is T);

  // ─── Request helpers ─────────────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    Options? options,
  }) =>
      dio.get<T>(path, queryParameters: params, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      dio.put<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(String path, {Options? options}) =>
      dio.delete<T>(path, options: options);

  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    Options? options,
  }) =>
      dio.post<T>(
        path,
        data: formData,
        options: (options ?? Options()).copyWith(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );

  Future<Response> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) =>
      dio.download(url, savePath, onReceiveProgress: onReceiveProgress);

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  static String _trailingSlash(String url) =>
      url.endsWith('/') ? url : '$url/';
}
