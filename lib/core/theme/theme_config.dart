// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_kit/core/storage/secure_storage_service.dart';
import 'app_theme.dart';

// ─── Theme Preset ─────────────────────────────────────────────────────────────
enum AppThemePreset {
  ocean('Ocean Blue', Color(0xFF2563EB)),
  violet('Deep Violet', Color(0xFF7C3AED)),
  rose('Rose Garden', Color(0xFFE11D48)),
  emerald('Emerald', Color(0xFF059669)),
  amber('Amber Sun', Color(0xFFD97706)),
  slate('Slate Pro', Color(0xFF475569)),
  indigo('Indigo', Color(0xFF4338CA)),
  teal('Teal', Color(0xFF0D9488)),
  pink('Pink Blossom', Color(0xFFDB2777)),
  orange('Sunset', Color(0xFFEA580C)),
  custom('Custom', Colors.transparent);

  final String label;
  final Color color;
  const AppThemePreset(this.label, this.color);
}

// ─── Font Preset ──────────────────────────────────────────────────────────────
enum AppFontPreset {
  inter('Inter', 'Inter'),
  roboto('Roboto', 'Roboto'),
  poppins('Poppins', 'Poppins'),
  nunito('Nunito', 'Nunito'),
  openSans('Open Sans', 'Open Sans'),
  lato('Lato', 'Lato'),
  sourceSans('Source Sans', 'Source Sans 3');

  final String label;
  final String family;
  const AppFontPreset(this.label, this.family);
}

// ─── Radius Scale ─────────────────────────────────────────────────────────────
enum AppRadiusScale {
  none('None', 0),
  small('Small', 4),
  medium('Medium', 8),
  large('Large', 12),
  xlarge('X-Large', 16),
  rounded('Rounded', 24),
  pill('Pill', 32);

  final String label;
  final double value;
  const AppRadiusScale(this.label, this.value);
}

// ─── ThemeConfig Model ────────────────────────────────────────────────────────
class ThemeConfig {
  final ThemeMode mode;
  final AppThemePreset preset;
  final Color customColor;
  final AppFontPreset font;
  final AppRadiusScale radiusScale;
  final VisualDensity density;
  final double fontSizeScale; // 0.8 – 1.3
  final bool highContrast;
  final bool reduceAnimations;
  final bool systemFont;

  const ThemeConfig({
    this.mode = ThemeMode.system,
    this.preset = AppThemePreset.ocean,
    this.customColor = const Color(0xFF2563EB),
    this.font = AppFontPreset.inter,
    this.radiusScale = AppRadiusScale.large,
    this.density = VisualDensity.standard,
    this.fontSizeScale = 1.0,
    this.highContrast = false,
    this.reduceAnimations = false,
    this.systemFont = false,
  });

  Color get effectiveColor =>
      preset == AppThemePreset.custom ? customColor : preset.color;

  ThemeConfig copyWith({
    ThemeMode? mode,
    AppThemePreset? preset,
    Color? customColor,
    AppFontPreset? font,
    AppRadiusScale? radiusScale,
    VisualDensity? density,
    double? fontSizeScale,
    bool? highContrast,
    bool? reduceAnimations,
    bool? systemFont,
  }) => ThemeConfig(
    mode: mode ?? this.mode,
    preset: preset ?? this.preset,
    customColor: customColor ?? this.customColor,
    font: font ?? this.font,
    radiusScale: radiusScale ?? this.radiusScale,
    density: density ?? this.density,
    fontSizeScale: fontSizeScale ?? this.fontSizeScale,
    highContrast: highContrast ?? this.highContrast,
    reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    systemFont: systemFont ?? this.systemFont,
  );

  Map<String, String> toMap() => {
    'mode': mode.name,
    'preset': preset.name,
    'customColor': customColor.value.toString(),
    'font': font.name,
    'radiusScale': radiusScale.name,
    'fontSizeScale': fontSizeScale.toString(),
    'highContrast': highContrast.toString(),
    'reduceAnimations': reduceAnimations.toString(),
    'systemFont': systemFont.toString(),
  };

  factory ThemeConfig.fromMap(Map<String, String> map) {
    return ThemeConfig(
      mode: ThemeMode.values.firstWhere(
        (e) => e.name == map['mode'], orElse: () => ThemeMode.system),
      preset: AppThemePreset.values.firstWhere(
        (e) => e.name == map['preset'], orElse: () => AppThemePreset.ocean),
      customColor: Color(int.tryParse(map['customColor'] ?? '') ?? 0xFF2563EB),
      font: AppFontPreset.values.firstWhere(
        (e) => e.name == map['font'], orElse: () => AppFontPreset.inter),
      radiusScale: AppRadiusScale.values.firstWhere(
        (e) => e.name == map['radiusScale'], orElse: () => AppRadiusScale.large),
      fontSizeScale: double.tryParse(map['fontSizeScale'] ?? '1.0') ?? 1.0,
      highContrast: map['highContrast'] == 'true',
      reduceAnimations: map['reduceAnimations'] == 'true',
      systemFont: map['systemFont'] == 'true',
    );
  }
}

// ─── ThemeConfig Notifier ─────────────────────────────────────────────────────
class ThemeConfigNotifier extends Notifier<ThemeConfig> {

  @override
  ThemeConfig build() {
    _load();
    return const ThemeConfig();
  }

  void _load() async {
    try {
      final keys = const ThemeConfig().toMap().keys.toList();
      final entries = await Future.wait(
        keys.map((k) => SecureStorageService.instance.read('tc_$k')),
      );
      final map = Map.fromIterables(keys, entries.map((v) => v ?? ''));
      if (map.values.any((v) => v.isNotEmpty)) {
        state = ThemeConfig.fromMap(map);
      }
    } catch (_) {}
  }

  void _save() async {
    final map = state.toMap();
    for (final entry in map.entries) {
      await SecureStorageService.instance.write('tc_${entry.key}', entry.value);
    }
  }

  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    _save();
  }

  void setPreset(AppThemePreset preset) {
    state = state.copyWith(preset: preset);
    _save();
  }

  void setCustomColor(Color color) {
    state = state.copyWith(preset: AppThemePreset.custom, customColor: color);
    _save();
  }

  void setFont(AppFontPreset font) {
    state = state.copyWith(font: font);
    _save();
  }

  void setRadiusScale(AppRadiusScale scale) {
    state = state.copyWith(radiusScale: scale);
    _save();
  }

  void setDensity(VisualDensity density) {
    state = state.copyWith(density: density);
    _save();
  }

  void setFontScale(double scale) {
    state = state.copyWith(fontSizeScale: scale.clamp(0.8, 1.3));
    _save();
  }

  void toggleHighContrast() {
    state = state.copyWith(highContrast: !state.highContrast);
    _save();
  }

  void toggleReduceAnimations() {
    state = state.copyWith(reduceAnimations: !state.reduceAnimations);
    _save();
  }

  void toggleDarkMode() {
    final next = state.mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setMode(next);
  }

  void reset() {
    state = const ThemeConfig();
    _save();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────
final themeConfigProvider =
    NotifierProvider<ThemeConfigNotifier, ThemeConfig>(ThemeConfigNotifier.new);

final appThemeModeProvider = Provider<ThemeMode>((ref) =>
    ref.watch(themeConfigProvider).mode);

final appLightThemeProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(themeConfigProvider);
  return AppTheme.fromColor(config.effectiveColor, dark: false);
});

final appDarkThemeProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(themeConfigProvider);
  return AppTheme.fromColor(config.effectiveColor, dark: true);
});
