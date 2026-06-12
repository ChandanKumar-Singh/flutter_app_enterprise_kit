import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> delays;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.delays = const [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ],
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['_retryCount'] as int?) ?? 0;
    if (_shouldRetry(err) && attempt < maxRetries) {
      err.requestOptions.extra['_retryCount'] = attempt + 1;
      await Future.delayed(delays[attempt]);
      try {
        handler.resolve(await dio.fetch(err.requestOptions));
        return;
      } catch (_) {}
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) =>
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.type == DioExceptionType.connectionError ||
      (err.response?.statusCode ?? 0) >= 500;
}
