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

  ApiClient() {
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
      CacheInterceptor(),
      RetryInterceptor(dio: dio),
      MetricsInterceptor(),
      ErrorInterceptor(),
      if (EnvConfig.enableLogging) LoggingInterceptor(),
    ]);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params, Options? options}) =>
      dio.get<T>(path, queryParameters: params, options: options);

  Future<Response<T>> post<T>(String path, {dynamic data, Options? options}) =>
      dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(String path, {dynamic data, Options? options}) =>
      dio.put<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(String path, {dynamic data, Options? options}) =>
      dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(String path, {Options? options}) =>
      dio.delete<T>(path, options: options);

  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) =>
      dio.post<T>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );

  Future<Response> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) =>
      dio.download(url, savePath, onReceiveProgress: onReceiveProgress);
}
