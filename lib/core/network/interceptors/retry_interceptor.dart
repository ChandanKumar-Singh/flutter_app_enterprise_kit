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
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Per-request opt-out: pass extra['noRetry'] = true to disable retries.
    if (err.requestOptions.extra['noRetry'] == true) {
      handler.next(err);
      return;
    }

    // Per-request override: pass extra['maxRetries'] = N to override count.
    final perRequestMax =
        (err.requestOptions.extra['maxRetries'] as int?) ?? maxRetries;

    // Per-request delay override: extra['retryDelayMs'] = milliseconds per attempt.
    final delayOverrideMs =
        err.requestOptions.extra['retryDelayMs'] as int?;

    final attempt =
        (err.requestOptions.extra['_retryCount'] as int?) ?? 0;

    if (_shouldRetry(err) && attempt < perRequestMax) {
      err.requestOptions.extra['_retryCount'] = attempt + 1;

      Duration delay;
      if (delayOverrideMs != null) {
        delay = Duration(milliseconds: delayOverrideMs);
      } else if (attempt < delays.length) {
        delay = delays[attempt];
      } else {
        delay = delays.last;
      }

      await Future.delayed(delay);

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
