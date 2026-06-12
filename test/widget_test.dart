import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_kit/app.dart';

void main() {
  testWidgets('App smoke test — renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EnterpriseApp()),
    );
    // Allow async providers (theme load, etc.) to settle
    await tester.pumpAndSettle(const Duration(seconds: 3));
    // App renders — MaterialApp.router is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
