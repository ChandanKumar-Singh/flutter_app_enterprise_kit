import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_kit/core/bootstrap/app_flavor.dart';
import 'package:enterprise_kit/core/bootstrap/env_config.dart';
import 'package:enterprise_kit/core/di/injection.dart';
import 'package:enterprise_kit/core/debug/app_logger.dart';
import 'package:enterprise_kit/core/services/app_analytics_service.dart';
import 'package:enterprise_kit/core/services/app_device_info_service.dart';
import 'package:enterprise_kit/core/notifications/app_notification_service.dart';
import 'package:enterprise_kit/core/data/app_cache_manager.dart';
import 'package:enterprise_kit/core/storage/app_encrypted_storage.dart';
import 'package:enterprise_kit/core/feature_flags/app_feature_flags.dart';
import 'package:enterprise_kit/app.dart';

class AppBootstrap {
  AppBootstrap._();

  static Future<void> run(AppFlavor flavor) async {
    await runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        // 1. Environment
        EnvConfig.init(flavor);

        // 2. Orientation
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        // 3. Status bar style
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        );

        // 4. DI
        await configureDependencies();

        // 5a. Device info (async, non-blocking for rest of boot)
        unawaited(AppDeviceInfoService.instance.initialize());

        // 5b. Analytics (no-op in debug, real backend injected in prod)
        AppAnalyticsService.init();

        // 5c. Cache manager (L1+L2 strategy layer)
        await AppCacheManager.instance.initialize();

        // 5d. Encrypted storage
        await AppEncryptedStorage.instance.initialize();

        // 5e. Feature flags (fetch async, non-blocking)
        unawaited(AppFeatureFlags.instance.fetch());

        // 5f. Notifications
        await AppNotificationService.instance.initialize();

        // 6. Flutter error handler
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          AppLogger.instance.e(
            'Flutter error',
            error: details.exception,
            stackTrace: details.stack,
          );
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          AppLogger.instance.e('Platform error', error: error, stackTrace: stack);
          return true;
        };

        // 6. Launch
        runApp(
          ProviderScope(
            observers: kDebugMode ? [_RiverpodLogger()] : [],
            child: const EnterpriseApp(),
          ),
        );
      },
      (error, stack) {
        AppLogger.instance.e('Uncaught error', error: error, stackTrace: stack);
      },
    );
  }
}

// Riverpod 3: ProviderObserver must be base/final/sealed
base class _RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    AppLogger.instance.d(
      '[Riverpod] ${context.provider.name ?? context.provider.runtimeType}: $newValue',
    );
  }
}
