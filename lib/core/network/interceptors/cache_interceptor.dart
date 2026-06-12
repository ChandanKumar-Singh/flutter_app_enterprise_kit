import 'package:dio/dio.dart';

class CacheEntry {
  final dynamic data;
  final DateTime expiry;
  CacheEntry(this.data, this.expiry);
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class CacheInterceptor extends Interceptor {
  final _cache = <String, CacheEntry>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET') { handler.next(options); return; }
    final key = _key(options);
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      handler.resolve(Response(requestOptions: options, data: entry.data, statusCode: 200,
          extra: {'fromCache': true}));
      return;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET') {
      final ttl = response.requestOptions.extra['cacheTtl'] as Duration?;
      if (ttl != null) _cache[_key(response.requestOptions)] =
          CacheEntry(response.data, DateTime.now().add(ttl));
    }
    handler.next(response);
  }

  String _key(RequestOptions o) => '${o.method}:${o.uri}';
  void clearAll() => _cache.clear();
  void clearKey(String key) => _cache.remove(key);
}
