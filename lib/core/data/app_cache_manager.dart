// ─── AppCacheManager ──────────────────────────────────────────────────────────
// TTL-based in-memory + persistent cache for repository data.
//
// Features:
//   • Memory cache (L1) — fast Map lookup, lost on app restart
//   • Persistent cache (L2) — SharedPreferences JSON, survives restart
//   • Per-entry TTL with stale detection
//   • Manual invalidation (single key, pattern, all)
//   • Cache statistics for debugging / dev console
//
// Usage:
//   final cache = AppCacheManager.instance;
//   await cache.set('users/list', usersJson, ttl: Duration(minutes: 5));
//   final cached = await cache.get('users/list');
//   await cache.invalidate('users/');  // invalidate by prefix
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Cache entry ───────────────────────────────────────────────────────────────

class AppCacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;
  final String? etag;

  const AppCacheEntry({
    required this.data,
    required this.cachedAt,
    required this.ttl,
    this.etag,
  });

  bool get isExpired =>
      DateTime.now().isAfter(cachedAt.add(ttl));

  bool get isStale => isExpired;

  Duration get age => DateTime.now().difference(cachedAt);

  Duration get remaining {
    final expiry = cachedAt.add(ttl);
    final r = expiry.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  Map<String, dynamic> toJson() => {
        'cachedAt': cachedAt.toIso8601String(),
        'ttlMs': ttl.inMilliseconds,
        if (etag != null) 'etag': etag,
        // data must be JSON-serialisable — callers handle this
      };
}

// ── Cache statistics ──────────────────────────────────────────────────────────

class AppCacheStats {
  final int memoryEntries;
  final int persistentEntries;
  final int hits;
  final int misses;
  final int evictions;

  const AppCacheStats({
    required this.memoryEntries,
    required this.persistentEntries,
    required this.hits,
    required this.misses,
    required this.evictions,
  });

  double get hitRate => (hits + misses) == 0 ? 0 : hits / (hits + misses);

  @override
  String toString() =>
      'CacheStats(mem: $memoryEntries, disk: $persistentEntries, '
      'hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
}

// ── Manager ───────────────────────────────────────────────────────────────────

class AppCacheManager {
  AppCacheManager._();
  static final AppCacheManager instance = AppCacheManager._();

  static const _diskPrefix = 'app_cache_';

  // L1: Memory cache (Map<key, {data, metadata}>)
  final _memCache = <String, _MemEntry>{};

  // Stats
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  SharedPreferences? _prefs;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Set ─────────────────────────────────────────────────────────────────────

  /// Store a JSON-serialisable value in L1 + L2 cache.
  Future<void> set(
    String key,
    dynamic data, {
    Duration ttl = const Duration(minutes: 5),
    String? etag,
    bool persistToDisk = true,
  }) async {
    final now = DateTime.now();
    _memCache[key] = _MemEntry(
      data: data,
      cachedAt: now,
      ttl: ttl,
      etag: etag,
    );

    if (persistToDisk && _prefs != null) {
      try {
        final payload = jsonEncode({
          'data': data,
          'cachedAt': now.toIso8601String(),
          'ttlMs': ttl.inMilliseconds,
          if (etag != null) 'etag': etag,
        });
        await _prefs!.setString('$_diskPrefix$key', payload);
      } catch (e) {
        debugPrint('[AppCacheManager] Disk write error for "$key": $e');
      }
    }
  }

  // ── Get ─────────────────────────────────────────────────────────────────────

  /// Returns cached data or null if missing / expired.
  Future<dynamic> get(String key, {bool allowStale = false}) async {
    // L1 memory
    final mem = _memCache[key];
    if (mem != null) {
      if (!mem.isExpired || allowStale) {
        _hits++;
        return mem.data;
      }
      _memCache.remove(key);
    }

    // L2 disk
    if (_prefs != null) {
      try {
        final stored = _prefs!.getString('$_diskPrefix$key');
        if (stored != null) {
          final map = jsonDecode(stored) as Map<String, dynamic>;
          final cachedAt = DateTime.parse(map['cachedAt'] as String);
          final ttl = Duration(milliseconds: map['ttlMs'] as int);
          final isExpired =
              DateTime.now().isAfter(cachedAt.add(ttl));

          if (!isExpired || allowStale) {
            // Promote to L1
            _memCache[key] = _MemEntry(
              data: map['data'],
              cachedAt: cachedAt,
              ttl: ttl,
              etag: map['etag'] as String?,
            );
            _hits++;
            return map['data'];
          }
        }
      } catch (e) {
        debugPrint('[AppCacheManager] Disk read error for "$key": $e');
      }
    }

    _misses++;
    return null;
  }

  /// Returns true if a non-expired entry exists.
  Future<bool> has(String key) async => (await get(key)) != null;

  /// Returns the ETag of the cached entry, if any.
  String? getEtag(String key) => _memCache[key]?.etag;

  // ── Invalidate ───────────────────────────────────────────────────────────────

  /// Invalidate a single key.
  Future<void> invalidate(String key) async {
    _memCache.remove(key);
    await _prefs?.remove('$_diskPrefix$key');
    _evictions++;
  }

  /// Invalidate all keys matching [prefix].
  Future<void> invalidateByPrefix(String prefix) async {
    final memKeys = _memCache.keys.where((k) => k.startsWith(prefix)).toList();
    for (final k in memKeys) {
      _memCache.remove(k);
      _evictions++;
    }
    if (_prefs != null) {
      final diskKeys = _prefs!
          .getKeys()
          .where((k) => k.startsWith('$_diskPrefix$prefix'))
          .toList();
      for (final k in diskKeys) {
        await _prefs!.remove(k);
      }
    }
  }

  /// Clear all cache entries.
  Future<void> clearAll() async {
    _evictions += _memCache.length;
    _memCache.clear();
    if (_prefs != null) {
      final diskKeys = _prefs!
          .getKeys()
          .where((k) => k.startsWith(_diskPrefix))
          .toList();
      for (final k in diskKeys) {
        await _prefs!.remove(k);
      }
    }
    debugPrint('[AppCacheManager] Cleared ✓');
  }

  // ── Statistics ───────────────────────────────────────────────────────────────

  AppCacheStats get stats {
    final diskEntries = _prefs?.getKeys()
            .where((k) => k.startsWith(_diskPrefix))
            .length ??
        0;
    return AppCacheStats(
      memoryEntries: _memCache.length,
      persistentEntries: diskEntries,
      hits: _hits,
      misses: _misses,
      evictions: _evictions,
    );
  }

  void resetStats() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
  }
}

// ── Internal memory entry ─────────────────────────────────────────────────────

class _MemEntry {
  final dynamic data;
  final DateTime cachedAt;
  final Duration ttl;
  final String? etag;

  bool get isExpired => DateTime.now().isAfter(cachedAt.add(ttl));

  const _MemEntry({
    required this.data,
    required this.cachedAt,
    required this.ttl,
    this.etag,
  });
}
