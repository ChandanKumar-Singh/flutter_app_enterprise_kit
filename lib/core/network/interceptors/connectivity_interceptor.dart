import 'package:dio/dio.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final hasConnection = await InternetConnection().hasInternetAccess;
    if (!hasConnection) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      ));
      return;
    }
    handler.next(options);
  }
}
