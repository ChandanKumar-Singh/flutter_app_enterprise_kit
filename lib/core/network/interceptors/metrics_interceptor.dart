import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/debug/app_logger.dart';

class MetricsInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_startTime'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode ?? 0);
    handler.next(err);
  }

  void _log(RequestOptions o, int? status) {
    final start = o.extra['_startTime'] as int?;
    if (start == null) return;
    final ms = DateTime.now().millisecondsSinceEpoch - start;
    AppLogger.instance.d('⏱ ${o.method} ${o.path} → ${status ?? '?'} (${ms}ms)');
  }
}
