// ─── AppApiServiceRegistry ────────────────────────────────────────────────────
// Named store for multiple IApiClientService instances.
//
// Bootstrap (e.g. in AppBootstrap.init):
//   AppApiServiceRegistry.registerAll({
//     AppApiServiceRegistry.kApp:      AppApiClientService(config: AppApiClientConfig.production()),
//     AppApiServiceRegistry.kShowcase: AppApiClientService(config: AppApiClientConfig.jsonPlaceholder()),
//     AppApiServiceRegistry.kMock:     MockApiClientService(),
//     'payments':  AppApiClientService(config: AppApiClientConfig.withDataEnvelope(baseUrl: 'https://pay.myapp.com')),
//     'analytics': AppApiClientService(config: AppApiClientConfig.withResultEnvelope(baseUrl: 'https://analytics.myapp.com')),
//   });
//
// Usage anywhere:
//   AppApiServiceRegistry.app.get<List<Post>>('posts', ...);
//   AppApiServiceRegistry.get('payments').post<Order>('checkout', ...);
// ─────────────────────────────────────────────────────────────────────────────

import 'package:enterprise_kit/core/network/i_api_client_service.dart';

class AppApiServiceRegistry {
  AppApiServiceRegistry._();

  static final _registry = <String, IApiClientService>{};

  // ─── Standard keys ──────────────────────────────────────────────────────

  static const String kApp      = 'app';
  static const String kShowcase = 'showcase';
  static const String kMock     = 'mock';

  // ─── Registration ────────────────────────────────────────────────────────

  /// Register a single named service.
  static void register(String key, IApiClientService service) =>
      _registry[key] = service;

  /// Register multiple services at once (e.g. in bootstrap).
  static void registerAll(Map<String, IApiClientService> services) =>
      _registry.addAll(services);

  /// Remove a service from the registry.
  static void unregister(String key) => _registry.remove(key);

  /// Clear the entire registry.
  static void clear() => _registry.clear();

  // ─── Retrieval ────────────────────────────────────────────────────────────

  /// Retrieve a service by key. Throws [StateError] if not registered.
  static IApiClientService get(String key) {
    final svc = _registry[key];
    if (svc == null) {
      throw StateError(
        'AppApiServiceRegistry: no service registered for key "$key".\n'
        'Registered keys: ${registeredKeys.join(', ')}\n'
        'Did you call registerAll() in bootstrap?',
      );
    }
    return svc;
  }

  /// Retrieve a service as a specific type [T].
  static T getAs<T extends IApiClientService>(String key) => get(key) as T;

  /// Returns null if the key is not registered.
  static IApiClientService? maybeGet(String key) => _registry[key];

  // ─── Typed shortcuts ──────────────────────────────────────────────────────

  /// Default production API client.
  static IApiClientService get app => get(kApp);

  /// Showcase / demo client (JSONPlaceholder).
  static IApiClientService get showcase => get(kShowcase);

  /// Mock client for testing.
  static IApiClientService get mock => get(kMock);

  // ─── Inspection ───────────────────────────────────────────────────────────

  static bool isRegistered(String key)   => _registry.containsKey(key);
  static List<String> get registeredKeys => List.unmodifiable(_registry.keys);
  static int get count                   => _registry.length;
}
