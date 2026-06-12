import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class AppHelpers {
  AppHelpers._();

  // ── Delay / debounce ───────────────────────────────────────────────────────
  static Future<void> delay(Duration duration) => Future.delayed(duration);
  static Future<void> delayMs(int ms) => delay(Duration(milliseconds: ms));

  // ── UUID ──────────────────────────────────────────────────────────────────
  static String uuid() => const Uuid().v4();
  static String shortId() => const Uuid().v4().replaceAll('-', '').substring(0, 12);

  // ── Random ────────────────────────────────────────────────────────────────
  static final _rng = Random();
  static int randomInt(int min, int max) => min + _rng.nextInt(max - min);
  static double randomDouble({double min = 0, double max = 1}) =>
      min + _rng.nextDouble() * (max - min);
  static T randomItem<T>(List<T> list) => list[_rng.nextInt(list.length)];

  // ── Clipboard ─────────────────────────────────────────────────────────────
  static Future<void> copyToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  static Future<String?> readFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  // ── URL Launcher ──────────────────────────────────────────────────────────
  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openEmail(String email, {String? subject, String? body}) {
    final params = <String, String>{};
    if (subject != null) params['subject'] = subject;
    if (body != null) params['body'] = body;
    final uri = Uri(scheme: 'mailto', path: email, queryParameters: params.isEmpty ? null : params);
    return launchUrl(uri);
  }

  static Future<bool> openPhone(String phone) =>
      launchUrl(Uri(scheme: 'tel', path: phone));

  static Future<bool> openSms(String phone, {String? message}) {
    final params = message != null ? {'body': message} : null;
    return launchUrl(Uri(scheme: 'sms', path: phone, queryParameters: params));
  }

  static Future<bool> openMaps(double lat, double lng, {String? label}) =>
      launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng'));

  // ── Share ─────────────────────────────────────────────────────────────────
  static Future<void> share(String text, {String? subject}) =>
      Share.share(text, subject: subject);

  static Future<void> shareFiles(List<String> paths, {String? text}) =>
      Share.shareXFiles(paths.map((p) => XFile(p)).toList(), text: text);

  // ── Haptics ───────────────────────────────────────────────────────────────
  static Future<void> hapticLight() => HapticFeedback.lightImpact();
  static Future<void> hapticMedium() => HapticFeedback.mediumImpact();
  static Future<void> hapticHeavy() => HapticFeedback.heavyImpact();
  static Future<void> hapticSelection() => HapticFeedback.selectionClick();
  static Future<void> hapticVibrate() => HapticFeedback.vibrate();

  // ── System UI ─────────────────────────────────────────────────────────────
  static void setSystemBars({
    Color? statusBarColor,
    Brightness statusBarBrightness = Brightness.dark,
    Color? navBarColor,
    Brightness navBarBrightness = Brightness.dark,
  }) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: statusBarColor ?? Colors.transparent,
      statusBarIconBrightness: statusBarBrightness,
      systemNavigationBarColor: navBarColor,
      systemNavigationBarIconBrightness: navBarBrightness,
    ));
  }

  static void setPreferredOrientations(List<DeviceOrientation> orientations) =>
      SystemChrome.setPreferredOrientations(orientations);

  static void lockPortrait() => setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  static void unlockOrientations() => setPreferredOrientations(
      DeviceOrientation.values);

  // ── Safe operations ───────────────────────────────────────────────────────
  static T? tryCast<T>(dynamic value) => value is T ? value : null;

  static Future<T?> tryAsync<T>(Future<T> Function() fn) async {
    try { return await fn(); } catch (_) { return null; }
  }

  static T? trySync<T>(T Function() fn) {
    try { return fn(); } catch (_) { return null; }
  }

  // ── Color ─────────────────────────────────────────────────────────────────
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static bool isLightColor(Color color) => color.computeLuminance() > 0.5;

  static Color contrastColor(Color background) =>
      isLightColor(background) ? Colors.black87 : Colors.white;

  static Color hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    return '#${includeAlpha ? hex : hex.substring(2)}'.toUpperCase();
  }
}
