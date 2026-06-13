import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/bootstrap/env_config.dart';
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

  ApiClient() {
    cacheInterceptor   = CacheInterceptor();
    metricsInterceptor = MetricsInterceptor();

    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client': 'flutter',
          'X-Platform': 'mobile',
        },
      ),
    );

    dio.interceptors.addAll([
      ConnectivityInterceptor(),
      AuthInterceptor(),
      cacheInterceptor,
      RetryInterceptor(dio: dio),
      metricsInterceptor,
      ErrorInterceptor(),
      if (EnvConfig.enableLogging) LoggingInterceptor(),
    ]);
  }

  // ─── Runtime config ──────────────────────────────────────────────────────────

  /// Change base URL at runtime (e.g. switch env, white-label tenant).
  void updateBaseUrl(String url) =>
      dio.options.baseUrl = url.endsWith('/') ? url : '$url/';

  /// Merge additional default headers (applied to every request).
  void updateHeaders(Map<String, String> headers) =>
      dio.options.headers.addAll(headers);

  /// Remove a single default header (e.g. after sign-out).
  void removeHeader(String key) => dio.options.headers.remove(key);

  /// Override connect / receive / send timeouts at runtime.
  void updateTimeout({Duration? connect, Duration? receive, Duration? send}) {
    if (connect != null) dio.options.connectTimeout = connect;
    if (receive != null) dio.options.receiveTimeout = receive;
    if (send != null)    dio.options.sendTimeout    = send;
  }

  /// Convenience: set bearer token in default headers.
  void setAuthToken(String token) =>
      dio.options.headers['Authorization'] = 'Bearer $token';

  /// Remove bearer token from default headers.
  void clearAuthToken() => dio.options.headers.remove('Authorization');

  /// Wipe the entire in-memory response cache.
  void clearCache() => cacheInterceptor.clearAll();

  /// Wipe cache for a single key.
  void clearCacheKey(String key) => cacheInterceptor.clearKey(key);

  /// Add an interceptor dynamically (e.g. for A/B tracking, tenant-specific headers).
  void addInterceptor(Interceptor interceptor) =>
      dio.interceptors.add(interceptor);

  /// Remove all interceptors of a given type.
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
        options: (options ?? Options()).copyWith(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
      );

  Future<Response> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) =>
      dio.download(url, savePath, onReceiveProgress: onReceiveProgress);
}
