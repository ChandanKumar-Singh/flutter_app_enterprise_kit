import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_kit/core/storage/secure_storage_service.dart';
import 'app_theme.dart';

// ─── Theme Mode ───────────────────────────────────────────────────────────────
// Riverpod 3: StateNotifier removed — use Notifier
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSaved();
    return ThemeMode.system;
  }

  void _loadSaved() async {
    final saved = await SecureStorageService.instance.read(StorageKeys.themeMode);
    state = switch (saved) {
      'light' => ThemeMode.light,
      'dark'  => ThemeMode.dark,
      _       => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await SecureStorageService.instance.write(StorageKeys.themeMode, mode.name);
  }

  void toggle() =>
      setMode(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ─── Theme Seed Color ─────────────────────────────────────────────────────────
class ThemeColorNotifier extends Notifier<Color> {
  @override
  Color build() => const Color(0xFF2563EB);

  void setColor(Color color) => state = color;
}

final themeColorProvider =
    NotifierProvider<ThemeColorNotifier, Color>(ThemeColorNotifier.new);

// ─── Derived ThemeData providers ──────────────────────────────────────────────
final lightThemeProvider = Provider<ThemeData>((ref) {
  final color = ref.watch(themeColorProvider);
  return AppTheme.fromColor(color, dark: false);
});

final darkThemeProvider = Provider<ThemeData>((ref) {
  final color = ref.watch(themeColorProvider);
  return AppTheme.fromColor(color, dark: true);
});
