import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/errors/network_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: NetworkException.fromDioException(err),
      type: err.type,
      response: err.response,
    ));
  }
}
