import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  // ── Theme ──────────────────────────────────────────────────────────────────
  ThemeData    get theme     => Theme.of(this);
  ColorScheme  get colors    => Theme.of(this).colorScheme;
  TextTheme    get textTheme => Theme.of(this).textTheme;
  bool         get isDark    => Theme.of(this).brightness == Brightness.dark;
  /// Kept for backwards compat with existing callers.
  bool         get isDarkMode => isDark;

  // ── MediaQuery — modern static helpers (Flutter 3.10+) ────────────────────
  /// Full size. Prefer [screenWidth] / [screenHeight] for rebuild efficiency.
  Size         get size         => MediaQuery.sizeOf(this);
  double       get screenWidth  => size.width;
  double       get screenHeight => size.height;

  @Deprecated('Use specific MediaQuery aspects instead of mq to prevent unnecessary rebuilds')
  MediaQueryData get mq => MediaQuery.of(this);

  double       get statusBarHeight  => MediaQuery.paddingOf(this).top;
  double       get bottomBarHeight  => MediaQuery.paddingOf(this).bottom;

  double       get keyboardHeight   => MediaQuery.viewInsetsOf(this).bottom;
  bool         get isKeyboardOpen   => keyboardHeight > 0;

  double       get devicePixelRatio => MediaQuery.devicePixelRatioOf(this);
  bool         get isHighDensity    => devicePixelRatio >= 2.0;

  bool         get isPortrait   => MediaQuery.orientationOf(this) == Orientation.portrait;
  bool         get isLandscape  => MediaQuery.orientationOf(this) == Orientation.landscape;

  bool         get isDarkPlatform =>
      MediaQuery.platformBrightnessOf(this) == Brightness.dark;

  bool         get alwaysUse24HourFormat =>
      MediaQuery.alwaysUse24HourFormatOf(this);

  TextScaler   get textScaler => MediaQuery.textScalerOf(this);

  // ── Breakpoints ────────────────────────────────────────────────────────────
  bool get isPhone   => screenWidth < 640;
  bool get isTablet  => screenWidth >= 640 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  /// True on smaller tablets / large phones.
  bool get isMedium  => screenWidth >= 640;

  // ── Navigation ─────────────────────────────────────────────────────────────
  NavigatorState get navigator => Navigator.of(this);
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T>(Route<T> route) => Navigator.of(this).push(route);
  Future<T?> pushNamed<T>(String route, {Object? arguments}) =>
      Navigator.of(this).pushNamed(route, arguments: arguments);

  // ── Focus ──────────────────────────────────────────────────────────────────
  void unfocus() => FocusScope.of(this).unfocus();
  void requestFocus(FocusNode node) => FocusScope.of(this).requestFocus(node);

  // ── SnackBar ───────────────────────────────────────────────────────────────
  void showSnack(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      backgroundColor: backgroundColor,
    ));
  }

  void showSuccessSnack(String message) =>
      showSnack(message, backgroundColor: Colors.green.shade700);

  void showErrorSnack(String message) =>
      showSnack(message, backgroundColor: Theme.of(this).colorScheme.error);

  void showInfoSnack(String message) =>
      showSnack(message, backgroundColor: Colors.blue.shade700);

  void clearSnacks() => ScaffoldMessenger.of(this).clearSnackBars();
}
