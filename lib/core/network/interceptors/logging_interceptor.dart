import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/debug/app_logger.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    AppLogger.instance.d('→ ${o.method} ${o.uri}\n  Headers: ${o.headers}\n  Data: ${o.data}');
    h.next(o);
  }
  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    AppLogger.instance.d('← ${r.statusCode} ${r.requestOptions.uri}\n  Data: ${r.data}');
    h.next(r);
  }
  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    AppLogger.instance.e('✗ ${e.response?.statusCode} ${e.requestOptions.uri}', error: e);
    h.next(e);
  }
}
