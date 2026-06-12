import 'dart:convert';
import 'package:crypto/crypto.dart';

extension StringExtensions on String {
  // ── Validation ─────────────────────────────────────────────────────────────
  bool get isEmail => RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(this);

  bool get isPhone => RegExp(r'^\+?[0-9]{7,15}$').hasMatch(trim());

  bool get isUrl => Uri.tryParse(this)?.hasAbsolutePath ?? false;

  bool get isNumeric => double.tryParse(this) != null;

  bool get isAlpha => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => trim().isNotEmpty;

  bool get hasUppercase => contains(RegExp(r'[A-Z]'));

  bool get hasLowercase => contains(RegExp(r'[a-z]'));

  bool get hasDigit => contains(RegExp(r'[0-9]'));

  bool get hasSpecialChar => contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get isStrongPassword =>
      length >= 8 && hasUppercase && hasLowercase && hasDigit && hasSpecialChar;

  bool get isCreditCard {
    final cleaned = replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int n = int.parse(cleaned[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  // ── Formatting ─────────────────────────────────────────────────────────────
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  String get camelCase {
    final words = split(RegExp(r'[\s_\-]+'));
    if (words.isEmpty) return this;
    return words.first.toLowerCase() +
        words.skip(1).map((w) => w.capitalize).join();
  }

  String get snakeCase => replaceAllMapped(
      RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
      .replaceAll(RegExp(r'^_'), '');

  String get kebabCase => snakeCase.replaceAll('_', '-');

  String get initials {
    final words = trim().split(RegExp(r'\s+'));
    if (words.length == 1) return words[0].substring(0, words[0].length > 2 ? 2 : words[0].length).toUpperCase();
    return words.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  String truncate(int maxLength, {String ellipsis = '...'}) =>
      length <= maxLength ? this : '${substring(0, maxLength - ellipsis.length)}$ellipsis';

  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  String get digits => replaceAll(RegExp(r'[^0-9]'), '');

  String get letters => replaceAll(RegExp(r'[^a-zA-Z]'), '');

  String mask({int visibleStart = 0, int visibleEnd = 4, String char = '*'}) {
    if (length <= visibleStart + visibleEnd) return this;
    return '${substring(0, visibleStart)}${char * (length - visibleStart - visibleEnd)}${substring(length - visibleEnd)}';
  }

  String maskEmail() {
    final parts = split('@');
    if (parts.length != 2) return mask();
    return '${parts[0].mask(visibleStart: 1, visibleEnd: 1)}@${parts[1]}';
  }

  // ── Parsing ────────────────────────────────────────────────────────────────
  int? get toIntOrNull => int.tryParse(this);
  double? get toDoubleOrNull => double.tryParse(this);
  bool get toBool => toLowerCase() == 'true' || this == '1';
  DateTime? get toDateTimeOrNull => DateTime.tryParse(this);

  Map<String, dynamic>? get jsonDecodeOrNull {
    try { return jsonDecode(this) as Map<String, dynamic>; } catch (_) { return null; }
  }

  // ── Crypto ─────────────────────────────────────────────────────────────────
  String get md5Hash => md5.convert(utf8.encode(this)).toString();
  String get sha256Hash => sha256.convert(utf8.encode(this)).toString();

  String get toBase64 => base64.encode(utf8.encode(this));
  String get fromBase64 => utf8.decode(base64.decode(this));

  // ── Misc ───────────────────────────────────────────────────────────────────
  bool containsIgnoreCase(String other) => toLowerCase().contains(other.toLowerCase());

  String highlight(String query, {String open = '**', String close = '**'}) {
    if (query.isEmpty) return this;
    return replaceAllMapped(RegExp(RegExp.escape(query), caseSensitive: false),
        (m) => '$open${m.group(0)}$close');
  }

  List<String> get lines => split('\n');
  int get wordCount => trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  String repeat(int times) => List.filled(times, this).join();

  String removePrefix(String prefix) =>
      startsWith(prefix) ? substring(prefix.length) : this;

  String removeSuffix(String suffix) =>
      endsWith(suffix) ? substring(0, length - suffix.length) : this;
}

extension NullableStringExtensions on String? {
  String get orEmpty => this ?? '';
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
  String orDefault(String defaultValue) => (this == null || this!.isEmpty) ? defaultValue : this!;
}
