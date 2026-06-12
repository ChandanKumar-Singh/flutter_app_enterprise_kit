import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  // ── Theme ──────────────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── MediaQuery ─────────────────────────────────────────────────────────────
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => mq.size.width;
  double get screenHeight => mq.size.height;
  double get statusBarHeight => mq.padding.top;
  double get bottomBarHeight => mq.padding.bottom;
  double get keyboardHeight => mq.viewInsets.bottom;
  bool get isKeyboardOpen => mq.viewInsets.bottom > 0;
  bool get isTablet => screenWidth >= 768;
  bool get isPhone => screenWidth < 768;
  bool get isPortrait => mq.orientation == Orientation.portrait;
  bool get isLandscape => mq.orientation == Orientation.landscape;
  double get devicePixelRatio => mq.devicePixelRatio;
  bool get isHighDensity => devicePixelRatio >= 2;

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

  void showSuccessSnack(String message) => showSnack(message,
      backgroundColor: Colors.green.shade700);

  void showErrorSnack(String message) => showSnack(message,
      backgroundColor: Theme.of(this).colorScheme.error);

  void showInfoSnack(String message) => showSnack(message,
      backgroundColor: Colors.blue.shade700);

  void clearSnacks() => ScaffoldMessenger.of(this).clearSnackBars();
}
