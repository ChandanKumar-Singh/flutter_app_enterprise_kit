// ─── AppRepository ────────────────────────────────────────────────────────────
// Generic repository base with pluggable cache strategies.
//
// Strategies:
//   cacheFirst          — return cached data if fresh, else fetch
//   networkFirst        — always fetch, fall back to cache on error
//   staleWhileRevalidate — return stale cache immediately, refresh in background
//   networkOnly         — always fetch, no caching
//   cacheOnly           — return cached data or null, never fetch
//
// Usage:
//   class UserRepository extends AppRepository<User> {
//     @override
//     String cacheKey(String id) => 'users/$id';
//
//     @override
//     Duration get defaultTtl => const Duration(minutes: 10);
//
//     Future<User> getUser(String id) => fetchWithStrategy(
//       key: cacheKey(id),
//       fetcher: () => _api.getUser(id),
//       fromJson: User.fromJson,
//       toJson: (u) => u.toJson(),
//     );
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'app_cache_manager.dart';
import 'app_data_state.dart';

// ── Cache strategy ────────────────────────────────────────────────────────────

enum CacheStrategy {
  /// Return fresh cache immediately. Fetch only if expired.
  cacheFirst,

  /// Always fetch. Fall back to (possibly stale) cache on error.
  networkFirst,

  /// Return cached data immediately (even stale). Refresh in background.
  staleWhileRevalidate,

  /// Always fetch. Never read or write cache.
  networkOnly,

  /// Return cached data only. Never fetch.
  cacheOnly,
}

// ── Repository base ───────────────────────────────────────────────────────────

abstract class AppRepository {
  /// Default TTL for this repository's cache entries.
  Duration get defaultTtl => const Duration(minutes: 5);

  /// Default cache strategy.
  CacheStrategy get defaultStrategy => CacheStrategy.cacheFirst;

  final _cache = AppCacheManager.instance;

  // ── Core fetch method ───────────────────────────────────────────────────────

  /// Fetch data applying the given [strategy].
  ///
  /// [key]       — cache key
  /// [fetcher]   — async function that returns fresh data
  /// [fromJson]  — deserialise from cached JSON
  /// [toJson]    — serialise to JSON for caching
  /// [strategy]  — override the default strategy
  /// [ttl]       — override the default TTL
  Future<T> fetchWithStrategy<T>({
    required String key,
    required Future<T> Function() fetcher,
    required T Function(dynamic json) fromJson,
    required dynamic Function(T data) toJson,
    CacheStrategy? strategy,
    Duration? ttl,
  }) async {
    final effectiveStrategy = strategy ?? defaultStrategy;
    final effectiveTtl = ttl ?? defaultTtl;

    return switch (effectiveStrategy) {
      CacheStrategy.cacheFirst =>
        _cacheFirst(key, fetcher, fromJson, toJson, effectiveTtl),
      CacheStrategy.networkFirst =>
        _networkFirst(key, fetcher, fromJson, toJson, effectiveTtl),
      CacheStrategy.staleWhileRevalidate =>
        _staleWhileRevalidate(key, fetcher, fromJson, toJson, effectiveTtl),
      CacheStrategy.networkOnly =>
        _networkOnly(key, fetcher, toJson, effectiveTtl),
      CacheStrategy.cacheOnly =>
        _cacheOnly(key, fromJson),
    };
  }

  // ── Stream variant — emits AppDataState updates ────────────────────────────

  /// Stream version of [fetchWithStrategy].
  /// Immediately emits loading → cached (if available) → fresh data.
  Stream<AppDataState<T>> streamWithStrategy<T>({
    required String key,
    required Future<T> Function() fetcher,
    required T Function(dynamic json) fromJson,
    required dynamic Function(T data) toJson,
    CacheStrategy? strategy,
    Duration? ttl,
  }) async* {
    yield const AppDataState.loading();

    try {
      // Check cache first for immediate data
      final cached = await _cache.get(key, allowStale: true);
      if (cached != null) {
        yield AppDataState.data(fromJson(cached));
      }

      // Then fetch fresh
      final fresh = await fetcher();
      await _cache.set(
        key,
        toJson(fresh),
        ttl: ttl ?? defaultTtl,
      );
      yield AppDataState.data(fresh);
    } catch (e, s) {
      yield AppDataState.error(e, s);
    }
  }

  // ── Cache management helpers ─────────────────────────────────────────────────

  Future<void> invalidate(String key) => _cache.invalidate(key);

  Future<void> invalidateByPrefix(String prefix) =>
      _cache.invalidateByPrefix(prefix);

  Future<void> clearCache() => _cache.clearAll();

  // ── Strategies (private) ──────────────────────────────────────────────────

  Future<T> _cacheFirst<T>(
    String key,
    Future<T> Function() fetcher,
    T Function(dynamic) fromJson,
    dynamic Function(T) toJson,
    Duration ttl,
  ) async {
    final cached = await _cache.get(key);
    if (cached != null) return fromJson(cached);
    return _fetchAndCache(key, fetcher, toJson, ttl);
  }

  Future<T> _networkFirst<T>(
    String key,
    Future<T> Function() fetcher,
    T Function(dynamic) fromJson,
    dynamic Function(T) toJson,
    Duration ttl,
  ) async {
    try {
      return await _fetchAndCache(key, fetcher, toJson, ttl);
    } catch (e) {
      debugPrint('[AppRepository] Network failed for "$key", falling back to cache: $e');
      final cached = await _cache.get(key, allowStale: true);
      if (cached != null) return fromJson(cached);
      rethrow;
    }
  }

  Future<T> _staleWhileRevalidate<T>(
    String key,
    Future<T> Function() fetcher,
    T Function(dynamic) fromJson,
    dynamic Function(T) toJson,
    Duration ttl,
  ) async {
    final cached = await _cache.get(key, allowStale: true);

    if (cached != null) {
      // Return stale immediately, refresh in background
      unawaited(_fetchAndCache(key, fetcher, toJson, ttl).catchError(
        (e) => debugPrint('[AppRepository] Background revalidate failed "$key": $e'),
      ));
      return fromJson(cached);
    }

    // No cache — fetch synchronously
    return _fetchAndCache(key, fetcher, toJson, ttl);
  }

  Future<T> _networkOnly<T>(
    String key,
    Future<T> Function() fetcher,
    dynamic Function(T) toJson,
    Duration ttl,
  ) async {
    final data = await fetcher();
    // Still cache for fallback use if needed later
    await _cache.set(key, toJson(data), ttl: ttl);
    return data;
  }

  Future<T> _cacheOnly<T>(
    String key,
    T Function(dynamic) fromJson,
  ) async {
    final cached = await _cache.get(key, allowStale: true);
    if (cached != null) return fromJson(cached);
    throw const AppRepositoryException(
      'No cached data available for cache-only request.',
    );
  }

  Future<T> _fetchAndCache<T>(
    String key,
    Future<T> Function() fetcher,
    dynamic Function(T) toJson,
    Duration ttl,
  ) async {
    final data = await fetcher();
    await _cache.set(key, toJson(data), ttl: ttl);
    return data;
  }
}

// ── Exception ─────────────────────────────────────────────────────────────────

class AppRepositoryException implements Exception {
  final String message;
  const AppRepositoryException(this.message);

  @override
  String toString() => 'AppRepositoryException: $message';
}
