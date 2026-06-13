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
    // By default only GET is cached. Pass extra['forceCache'] = true to also
    // cache POST/other methods (e.g. search queries).
    final isGet = options.method == 'GET';
    final forceCache = options.extra['forceCache'] == true;

    if (!isGet && !forceCache) {
      handler.next(options);
      return;
    }

    // Per-request: pass extra['noCache'] = true to bypass cache reads.
    if (options.extra['noCache'] == true) {
      handler.next(options);
      return;
    }

    final key = _resolveKey(options);
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      handler.resolve(Response(
        requestOptions: options,
        data: entry.data,
        statusCode: 200,
        extra: {'fromCache': true, 'cacheKey': key},
      ));
      return;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options  = response.requestOptions;
    final isGet    = options.method == 'GET';
    final force    = options.extra['forceCache'] == true;
    final ttl      = options.extra['cacheTtl'] as Duration?;

    // Cache only if TTL is explicitly set (opt-in caching).
    if ((isGet || force) && ttl != null) {
      final key = _resolveKey(options);
      _cache[key] = CacheEntry(response.data, DateTime.now().add(ttl));
    }
    handler.next(response);
  }

  /// Prefer explicit extra['cacheKey'], else derive from method + URI.
  String _resolveKey(RequestOptions o) =>
      (o.extra['cacheKey'] as String?) ?? '${o.method}:${o.uri}';

  void clearAll() => _cache.clear();

  void clearKey(String key) => _cache.remove(key);

  /// Remove all entries that have already expired.
  void evictExpired() =>
      _cache.removeWhere((_, v) => v.isExpired);

  int get size => _cache.length;
}
