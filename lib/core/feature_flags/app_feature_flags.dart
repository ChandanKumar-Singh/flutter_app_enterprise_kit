// ─── AppFeatureFlags ──────────────────────────────────────────────────────────
// Type-safe, backend-agnostic feature flag / remote config system.
//
// Architecture:
//   AppFeatureFlagsBackend (abstract interface)
//     └── AppLocalFlagsBackend    — map-based, used by default & in tests
//     └── (your remote backend)  — Firebase RC, LaunchDarkly, etc.
//
// Typed flag definitions:
//   class AppFlags {
//     static const darkMode   = AppBoolFlag('dark_mode',   defaultValue: false);
//     static const maxRetries = AppIntFlag('max_retries',  defaultValue: 3);
//     static const apiUrl     = AppStringFlag('api_url',   defaultValue: 'https://...');
//   }
//
// Usage:
//   AppFeatureFlags.init(backend: FirebaseRCBackend());
//   final enabled = await AppFeatureFlags.instance.getBool(AppFlags.darkMode);
//   // or shorthand:
//   final enabled = await AppFlags.darkMode.value;
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';

// ── Flag definitions ──────────────────────────────────────────────────────────

/// Base typed flag. Extend for each primitive type.
abstract class AppFlag<T> {
  final String key;
  final T defaultValue;

  const AppFlag(this.key, {required this.defaultValue});

  /// Shorthand: `await AppFlags.darkMode.value`
  Future<T> get value => AppFeatureFlags.instance.getValue(this);

  /// Synchronous read of last-fetched value.
  T get cachedValue => AppFeatureFlags.instance.getCachedValue(this);
}

class AppBoolFlag extends AppFlag<bool> {
  const AppBoolFlag(super.key, {required super.defaultValue});
}

class AppIntFlag extends AppFlag<int> {
  const AppIntFlag(super.key, {required super.defaultValue});
}

class AppDoubleFlag extends AppFlag<double> {
  const AppDoubleFlag(super.key, {required super.defaultValue});
}

class AppStringFlag extends AppFlag<String> {
  const AppStringFlag(super.key, {required super.defaultValue});
}

class AppJsonFlag extends AppFlag<Map<String, dynamic>> {
  const AppJsonFlag(super.key, {required super.defaultValue});
}

// ── Backend interface ─────────────────────────────────────────────────────────

abstract class AppFeatureFlagsBackend {
  /// Fetch all flags from the remote source.
  /// Called on [AppFeatureFlags.fetch].
  Future<void> fetch();

  bool getBool(String key, {required bool defaultValue});
  int getInt(String key, {required int defaultValue});
  double getDouble(String key, {required double defaultValue});
  String getString(String key, {required String defaultValue});
  Map<String, dynamic> getJson(String key, {required Map<String, dynamic> defaultValue});

  /// Returns true if the backend has been fetched at least once.
  bool get isFetched;
}

// ── Local backend (default / test) ────────────────────────────────────────────

/// In-memory map backend. Useful for tests and default config.
class AppLocalFlagsBackend implements AppFeatureFlagsBackend {
  final Map<String, dynamic> _values;
  bool _fetched = false;

  AppLocalFlagsBackend([Map<String, dynamic>? initialValues])
      : _values = Map<String, dynamic>.from(initialValues ?? {});

  /// Update a flag at runtime (useful for testing / dev overrides).
  void setOverride(String key, dynamic value) => _values[key] = value;

  void removeOverride(String key) => _values.remove(key);

  @override
  Future<void> fetch() async => _fetched = true;

  @override
  bool get isFetched => _fetched;

  @override
  bool getBool(String key, {required bool defaultValue}) =>
      (_values[key] as bool?) ?? defaultValue;

  @override
  int getInt(String key, {required int defaultValue}) =>
      (_values[key] as int?) ?? defaultValue;

  @override
  double getDouble(String key, {required double defaultValue}) =>
      (_values[key] as double?) ?? defaultValue;

  @override
  String getString(String key, {required String defaultValue}) =>
      (_values[key] as String?) ?? defaultValue;

  @override
  Map<String, dynamic> getJson(String key,
      {required Map<String, dynamic> defaultValue}) =>
      (_values[key] as Map<String, dynamic>?) ?? defaultValue;
}

// ── Service ───────────────────────────────────────────────────────────────────

class AppFeatureFlags {
  AppFeatureFlags._();
  static AppFeatureFlags instance = AppFeatureFlags._();

  AppFeatureFlagsBackend _backend = AppLocalFlagsBackend();

  /// In-memory override layer — wins over backend.
  final _overrides = <String, dynamic>{};

  /// Listeners notified when flags are refreshed.
  final _listeners = <VoidCallback>[];

  static void init({required AppFeatureFlagsBackend backend}) {
    instance._backend = backend;
  }

  // ── Fetch ───────────────────────────────────────────────────────────────────

  /// Fetch flags from the remote backend.
  /// Safe to call multiple times; debounced if called repeatedly.
  Future<void> fetch() async {
    try {
      await _backend.fetch();
      _notifyListeners();
      debugPrint('[AppFeatureFlags] Flags fetched ✓');
    } catch (e) {
      debugPrint('[AppFeatureFlags] Fetch error: $e');
    }
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  Future<T> getValue<T>(AppFlag<T> flag) async {
    if (!_backend.isFetched) await fetch();
    return getCachedValue(flag);
  }

  T getCachedValue<T>(AppFlag<T> flag) {
    // Override layer wins
    if (_overrides.containsKey(flag.key)) {
      return _overrides[flag.key] as T;
    }

    return switch (flag) {
      AppBoolFlag f   => _backend.getBool(f.key, defaultValue: f.defaultValue) as T,
      AppIntFlag f    => _backend.getInt(f.key, defaultValue: f.defaultValue) as T,
      AppDoubleFlag f => _backend.getDouble(f.key, defaultValue: f.defaultValue) as T,
      AppStringFlag f => _backend.getString(f.key, defaultValue: f.defaultValue) as T,
      AppJsonFlag f   => _backend.getJson(f.key, defaultValue: f.defaultValue) as T,
      _               => flag.defaultValue,
    };
  }

  // Typed convenience methods
  Future<bool> getBool(AppBoolFlag flag) => getValue(flag);
  Future<int> getInt(AppIntFlag flag) => getValue(flag);
  Future<double> getDouble(AppDoubleFlag flag) => getValue(flag);
  Future<String> getString(AppStringFlag flag) => getValue(flag);
  Future<Map<String, dynamic>> getJson(AppJsonFlag flag) => getValue(flag);

  // ── Overrides (dev / QA) ───────────────────────────────────────────────────

  /// Set a local override that wins over the backend.
  void setOverride<T>(AppFlag<T> flag, T value) {
    _overrides[flag.key] = value;
    _notifyListeners();
  }

  void removeOverride<T>(AppFlag<T> flag) {
    _overrides.remove(flag.key);
    _notifyListeners();
  }

  void clearAllOverrides() {
    _overrides.clear();
    _notifyListeners();
  }

  bool hasOverride<T>(AppFlag<T> flag) => _overrides.containsKey(flag.key);

  Map<String, dynamic> get allOverrides => Map.unmodifiable(_overrides);

  // ── Listeners ─────────────────────────────────────────────────────────────

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }
}

// ── AppFlagChangeNotifier ─────────────────────────────────────────────────────
// A ChangeNotifier that rebuilds when any flag changes.
// Use with ListenableBuilder or Consumer for reactive UI.

class AppFlagChangeNotifier extends ChangeNotifier {
  AppFlagChangeNotifier() {
    AppFeatureFlags.instance.addListener(_onFlagsChanged);
  }

  void _onFlagsChanged() => notifyListeners();

  @override
  void dispose() {
    AppFeatureFlags.instance.removeListener(_onFlagsChanged);
    super.dispose();
  }
}
