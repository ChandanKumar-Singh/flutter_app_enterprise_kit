import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.instance.read(StorageKeys.accessToken);
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await _refreshToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        await SecureStorageService.instance.deleteAll();
      }
    }
    handler.next(err);
  }

  Future<String> _refreshToken() async {
    // Implement token refresh logic
    throw UnimplementedError('Token refresh not configured');
  }
}
