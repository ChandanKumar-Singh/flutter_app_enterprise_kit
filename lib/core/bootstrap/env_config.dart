import 'package:enterprise_kit/core/bootstrap/app_flavor.dart';

class EnvConfig {
  EnvConfig._();

  static late AppFlavor _flavor;
  static late String baseUrl;
  static late String wsUrl;
  static late bool enableLogging;
  static late bool enableDebugBanner;
  static late bool showDebugOverlay;

  static final _configs = {
    AppFlavor.development: _EnvData(
      baseUrl: 'https://api-dev.enterprise.com/v1',
      wsUrl: 'wss://ws-dev.enterprise.com',
      enableLogging: true,
      enableDebugBanner: true,
      showDebugOverlay: true,
    ),
    AppFlavor.staging: _EnvData(
      baseUrl: 'https://api-staging.enterprise.com/v1',
      wsUrl: 'wss://ws-staging.enterprise.com',
      enableLogging: true,
      enableDebugBanner: false,
      showDebugOverlay: false,
    ),
    AppFlavor.production: _EnvData(
      baseUrl: 'https://api.enterprise.com/v1',
      wsUrl: 'wss://ws.enterprise.com',
      enableLogging: false,
      enableDebugBanner: false,
      showDebugOverlay: false,
    ),
  };

  static void init(AppFlavor flavor) {
    _flavor = flavor;
    final cfg = _configs[flavor]!;
    baseUrl = cfg.baseUrl;
    wsUrl = cfg.wsUrl;
    enableLogging = cfg.enableLogging;
    enableDebugBanner = cfg.enableDebugBanner;
    showDebugOverlay = cfg.showDebugOverlay;
  }

  static AppFlavor get flavor => _flavor;
  static bool get isProduction => _flavor == AppFlavor.production;
  static bool get isDevelopment => _flavor == AppFlavor.development;
}

class _EnvData {
  final String baseUrl;
  final String wsUrl;
  final bool enableLogging;
  final bool enableDebugBanner;
  final bool showDebugOverlay;
  const _EnvData({
    required this.baseUrl,
    required this.wsUrl,
    required this.enableLogging,
    required this.enableDebugBanner,
    required this.showDebugOverlay,
  });
}
