import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_kit/app.dart';
import 'package:enterprise_kit/core/bootstrap/env_config.dart';
import 'package:enterprise_kit/core/bootstrap/app_flavor.dart';

void main() {
  setUp(() {
    EnvConfig.init(AppFlavor.development);
  });

  testWidgets('App smoke test — renders without crash', (WidgetTester tester) async {
    // Ignore layout overflow exceptions in widget smoke tests
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed by')) {
        return;
      }
      originalOnError?.call(details);
    };

    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    // Set screen size to prevent layout overflows during tests
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: EnterpriseApp()),
    );
    // Allow splash page delay to complete and trigger navigation
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(); // Start navigation transition
    await tester.pumpAndSettle(); // Settle home page animations

    // App renders — MaterialApp.router is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
